use regex::Regex;
use std::collections::HashMap;
use wasm_bindgen::prelude::wasm_bindgen;

#[wasm_bindgen]
pub fn letters(input: &str, wordlist: &str, min_word_length: usize) -> String {
    let downcased = input.to_ascii_lowercase();
    let cleaned = downcased.trim();

    let mut in_counts = HashMap::new();
    for c in cleaned.chars() {
        in_counts.entry(c).and_modify(|v| *v += 1).or_insert(1usize);
    }

    let pattern = format!("^[{cleaned}]{{{min_word_length},}}$");
    let matcher = Regex::new(&pattern).expect("The search pattern did not compile :(");

    let mut candidates = Vec::new();
    for line in wordlist.lines() {
        // Assumption: line is trimmed and lowercased
        if matcher.is_match(line) {
            let mut cand_counts = HashMap::new();
            for c in line.chars() {
                cand_counts
                    .entry(c)
                    .and_modify(|v| *v += 1)
                    .or_insert(1usize);
            }

            if cand_counts.into_iter().all(|(ch, f)| f <= in_counts[&ch]) {
                candidates.push(line.to_string());
            }
        }
    }

    candidates.sort_unstable_by(|a, b| a.len().cmp(&b.len()).reverse());

    // Because we can't currently return a Vec<String> - settle for a comma seperated String
    candidates.join(",")
}

#[test]
fn test_letters() {
    use flate2::read::GzDecoder;
    use std::fs::File;
    use std::io::Read;

    let mut reader = GzDecoder::new(File::open("wordlist.gz").unwrap());
    let wordlist = &mut String::new();
    reader
        .read_to_string(wordlist)
        .expect("The wordlist was not read :(");

    assert_eq!(letters("hello", wordlist, 3), "hello,hell,hole,ell,hoe");
    assert_eq!(letters("bye", wordlist, 3), "bye");
    assert_eq!(letters("bye", wordlist, 4), "");
}
