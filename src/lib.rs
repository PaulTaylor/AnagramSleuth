use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn letters(input: String, wordlist: Vec<String>) -> usize {
    let mut i = 0;
    for line in wordlist {
        let trimmed = line.trim().to_lowercase();
    }
    i
}

#[test]
fn test_letters() {
    use flate2::read::GzDecoder;
    use std::fs::File;

    let mut reader = GzDecoder::new(File::open("wordlist.gz").unwrap());
    let buf = &mut String::new();
    let _ = reader.read_to_string(buf);

    let wordlist: &[String] = buf.lines().map(|l| l.trim().to_lowercase()).collect();

    assert_eq!(letters("hello".into(), wordlist), 1)
}
