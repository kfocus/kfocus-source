package main

// Copyright (C) 2024 Simon Quigley <tsimonq2@ubuntu.com>
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 3
// of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

import (
    "flag"
    "fmt"
    "io/ioutil"
    "log"
    "os"
    "os/exec"
    "path/filepath"
    "strings"

    "github.com/snapcore/snapd/snap"
    "github.com/snapcore/snapd/interfaces/builtin"
    "gopkg.in/yaml.v2"
)

type seed struct {
    Snaps []struct {
        Name    string `yaml:"name"`
        Channel string `yaml:"channel"`
        File    string `yaml:"file"`
    } `yaml:"snaps"`
}

func main() {
    snap.SanitizePlugsSlots = builtin.SanitizePlugsSlots

    var seed_directory string
    flag.StringVar(&seed_directory, "seed", "/var/lib/snapd/seed", "Specify the seed directory")
    flag.Parse()

    snap_set := make(map[string]bool)

    snaps_dir := filepath.Join(seed_directory, "snaps")
    assertions_dir := filepath.Join(seed_directory, "assertions")
    seed_yaml := filepath.Join(seed_directory, "seed.yaml")

    ensure_seed_yaml(seed_yaml)

    existing_snaps_in_yaml := load_existing_snaps(seed_yaml)

    for _, snap_info := range flag.Args() {
        parts := strings.SplitN(snap_info, "=", 2)
        snap_name := parts[0]
        channel := "stable" // Default to stable if no channel is specified
        if len(parts) == 2 {
            channel = parts[1]
        }
        process_snap_with_prereqs(snap_name, channel, &snap_set, snaps_dir, assertions_dir, seed_yaml, existing_snaps_in_yaml)
    }

    essentialSnaps := []string{"snapd", "bare"}
    for _, snapName := range essentialSnaps {
        if !existing_snaps_in_yaml[snapName] {
            process_snap_with_prereqs(snapName, "stable", &snap_set, snaps_dir, assertions_dir, seed_yaml, existing_snaps_in_yaml)
        }
    }

    update_seed_yaml(snaps_dir, seed_yaml, snap_set, existing_snaps_in_yaml)

    remove_state_json(filepath.Join(seed_directory, "..", "state.json"))
    ensure_assertions(assertions_dir)
    validate_seed(seed_yaml)
}

func ensure_seed_yaml(seed_yaml string) {
    if _, err := os.Stat(seed_yaml); os.IsNotExist(err) {
        file, err := os.Create(seed_yaml)
        if err != nil {
            log.Fatalf("Failed to create seed.yaml: %v", err)
        }
        defer file.Close()
        file.WriteString("snaps:\n")
    }
}

func load_existing_snaps(seed_yaml string) map[string]bool {
    file, err := ioutil.ReadFile(seed_yaml)
    if err != nil {
        log.Fatalf("Failed to read seed.yaml: %v", err)
    }

    var seed_data seed
    if err := yaml.Unmarshal(file, &seed_data); err != nil {
        log.Fatalf("Failed to parse seed.yaml: %v", err)
    }

    existing := make(map[string]bool)
    for _, snap := range seed_data.Snaps {
        existing[snap.Name] = true
    }
    return existing
}

func update_seed_yaml(snaps_dir, seed_yaml string, snap_set map[string]bool, existing_snaps map[string]bool) {
    seed_data := load_seed_data(seed_yaml)

    for snap_name := range snap_set {
        if !existing_snaps[snap_name] {
            snap_files, err := filepath.Glob(filepath.Join(snaps_dir, fmt.Sprintf("%s_*.snap", snap_name)))
            if err != nil || len(snap_files) == 0 {
                log.Printf("No snap file found for %s", snap_name)
                return
            }

            snap_file := filepath.Base(snap_files[0])
            log.Printf(snap_file)

            // FIXME: should put the real name of the channel in here
            seed_data.Snaps = append(seed_data.Snaps, struct {
                Name    string `yaml:"name"`
                Channel string `yaml:"channel"`
                File    string `yaml:"file"`
            }{snap_name, "latest/stable", snap_file})
        }
    }

    // Marshal to YAML and write back to file
    data, err := yaml.Marshal(&seed_data)
    if err != nil {
        log.Fatalf("Failed to marshal seed data to YAML: %v", err)
    }

    if err := ioutil.WriteFile(seed_yaml, data, 0644); err != nil {
        log.Fatalf("Failed to write updated seed.yaml: %v", err)
    }
}

func load_seed_data(seed_yaml string) seed {
    file, err := ioutil.ReadFile(seed_yaml)
    if err != nil {
        log.Fatalf("Failed to read seed.yaml: %v", err)
    }

    var seed_data seed
    if err := yaml.Unmarshal(file, &seed_data); err != nil {
        log.Fatalf("Failed to parse seed.yaml: %v", err)
    }
    return seed_data
}

func remove_state_json(state_json_path string) {
    if _, err := os.Stat(state_json_path); err == nil {
        os.Remove(state_json_path)
    }
}

func validate_seed(seed_yaml string) {
    cmd := exec.Command("snap", "debug", "validate-seed", seed_yaml)
    if err := cmd.Run(); err != nil {
        log.Printf("Error validating seed: %v", err)
    }
}

func process_snap_with_prereqs(snap_name, channel string, snap_set *map[string]bool, snaps_dir, assertions_dir, seed_yaml string, existing_snaps_in_yaml map[string]bool) {
    if (*snap_set)[snap_name] {
        return
    }

    // Download the snap if not already processed or listed in seed.yaml
    if !existing_snaps_in_yaml[snap_name] {
        cmd := exec.Command("snap", "download", snap_name, "--channel="+channel, "--target-directory="+snaps_dir)
        if err := cmd.Run(); err != nil {
            log.Printf("Error downloading snap %s from channel %s: %v", snap_name, channel, err)
            return
        }
    }

    snap_files, err := filepath.Glob(filepath.Join(snaps_dir, fmt.Sprintf("%s_*.snap", snap_name)))
    if err != nil || len(snap_files) == 0 {
        log.Printf("No snap file found for %s in channel %s", snap_name, channel)
        return
    }

    snap_file := snap_files[0]

    cmd := exec.Command("unsquashfs", "-n", "-d", filepath.Join(snaps_dir, fmt.Sprintf("%s_meta", snap_name)), snap_file, "meta/snap.yaml")
    if err := cmd.Run(); err != nil {
        log.Printf("Error extracting meta/snap.yaml from snap %s: %v", snap_name, err)
        return
    }

    yaml_data, err := ioutil.ReadFile(filepath.Join(snaps_dir, fmt.Sprintf("%s_meta/meta/snap.yaml", snap_name)))
    if err != nil {
        log.Printf("Error reading snap.yaml file for %s: %v", snap_name, err)
        return
    }

    info, err := snap.InfoFromSnapYaml(yaml_data)
    if err != nil {
        log.Printf("Error parsing snap.yaml data for %s: %v", snap_name, err)
        return
    }

    (*snap_set)[snap_name] = true

    tracker := snap.SimplePrereqTracker{}
    missing_provider_content_tags := tracker.MissingProviderContentTags(info, nil)
    for provider_snap := range missing_provider_content_tags {
        if !(*snap_set)[provider_snap] {
            process_snap_with_prereqs(provider_snap, "stable", snap_set, snaps_dir, assertions_dir, seed_yaml, existing_snaps_in_yaml)
        }
    }

    if info.Base != "" && !(*snap_set)[info.Base] {
        process_snap_with_prereqs(info.Base, "stable", snap_set, snaps_dir, assertions_dir, seed_yaml, existing_snaps_in_yaml)
    }

    assert_files, err := filepath.Glob(filepath.Join(snaps_dir, "*.assert"))
    for _, file := range assert_files {
        target_path := filepath.Join(assertions_dir, filepath.Base(file))
        err := os.Rename(file, target_path)
        if err != nil {
            log.Printf("Failed to move %s to %s: %v", file, assertions_dir, err)
        }
    }

    os.RemoveAll(filepath.Join(snaps_dir, fmt.Sprintf("%s_meta", snap_name)))
}

func ensure_assertions(assertions_dir string) {
    model := "generic-classic"
    brand := "generic"
    series := "16"

    model_assertion_path := filepath.Join(assertions_dir, "model")
    account_key_assertion_path := filepath.Join(assertions_dir, "account-key")
    account_assertion_path := filepath.Join(assertions_dir, "account")

    // Check and generate model assertion
    if _, err := os.Stat(model_assertion_path); os.IsNotExist(err) {
        output, err := exec.Command("snap", "known", "--remote", "model", "series="+series, "model="+model, "brand-id="+brand).CombinedOutput()
        if err != nil {
            log.Fatalf("Failed to fetch model assertion: %v, Output: %s", err, string(output))
        }
        ioutil.WriteFile(model_assertion_path, output, 0644)
    }

    // Generate account-key assertion if not exists
    if _, err := os.Stat(account_key_assertion_path); os.IsNotExist(err) {
        signKeySha3 := grep_pattern(model_assertion_path, "sign-key-sha3-384: ")
        output, err := exec.Command("snap", "known", "--remote", "account-key", "public-key-sha3-384="+signKeySha3).CombinedOutput()
        if err != nil {
            log.Fatalf("Failed to fetch account-key assertion: %v, Output: %s", err, string(output))
        }
        ioutil.WriteFile(account_key_assertion_path, output, 0644)
    }

    // Generate account assertion if not exists
    if _, err := os.Stat(account_assertion_path); os.IsNotExist(err) {
        accountId := grep_pattern(account_key_assertion_path, "account-id: ")
        output, err := exec.Command("snap", "known", "--remote", "account", "account-id="+accountId).CombinedOutput()
        if err != nil {
            log.Fatalf("Failed to fetch account assertion: %v, Output: %s", err, string(output))
        }
        ioutil.WriteFile(account_assertion_path, output, 0644)
    }
}

func grep_pattern(filePath, pattern string) string {
    content, err := ioutil.ReadFile(filePath)
    if err != nil {
        log.Fatalf("Failed to read from file %s: %v", filePath, err)
    }
    lines := strings.Split(string(content), "\n")
    for _, line := range lines {
        if strings.Contains(line, pattern) {
            parts := strings.SplitN(line, ":", 2)
            if len(parts) == 2 {
                return strings.TrimSpace(parts[1])
            }
        }
    }
    log.Fatalf("Pattern %s not found in file %s", pattern, filePath)
    return ""
}
