use evalexpr::{eval, Value};
use regex::Regex;
use std::{
    cmp::Ordering,
    collections::{BTreeSet, HashMap, HashSet},
    hash::{Hash, Hasher},
};
use wasm_bindgen::prelude::wasm_bindgen;

#[wasm_bindgen]
#[must_use]
pub fn letters(input: &str, wordlist: &str, min_word_length: usize) -> String {
    let letters = Regex::new("[^a-z]").unwrap();
    let downcased = input.to_ascii_lowercase();
    let cleaned = letters.replace_all(downcased.trim(), "");

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

fn calculate(formula: &str) -> Option<usize> {
    let p = Regex::new("([0-9]+)").unwrap();
    let float_formula = p.replace_all(formula, r"$1.0");

    let r = eval(&float_formula)
        .and_then(|v: Value| v.as_float())
        .unwrap();

    if r.fract() == 0.0 && r > 0.0 {
        Some(r as usize)
    } else {
        None
    }
}

#[derive(Eq, Debug)]
struct Expression {
    formula: String,
    used: Vec<usize>,
    remaining: Vec<usize>,
    result: usize,
}

impl Ord for Expression {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        (self.formula.len(), &self.formula).cmp(&(other.formula.len(), &other.formula))
    }
}

impl PartialOrd for Expression {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl PartialEq for Expression {
    fn eq(&self, other: &Self) -> bool {
        self.cmp(other) == Ordering::Equal
    }
}

impl Hash for Expression {
    fn hash<H>(&self, state: &mut H)
    where
        H: Hasher,
    {
        let _ = &self.formula.hash(state);
    }
}

impl Expression {
    fn extend(&self, op: char, right: &Expression) -> Option<Expression> {
        /*
         * we adjust left/right so that the side that sorts lowest
         * by formula is on the left.  This ensures consistency and
         * means we don't add both (1 + 2) and (2 + 1) to the expression
         * list (as it's pointless).
         */
        let (left, right) = match op {
            '+' | '*' => {
                let mut temp = vec![self, right];
                temp.sort_by(|a, b| a.formula.cmp(&b.formula));
                (temp[0], temp[1])
            }
            _ => (self, right), // Noop
        };

        let mut remaining = left.remaining.clone();
        let mut used = left.used.clone();

        // Need to make sure that the numbers used on the right are
        // remaining on the left.  This is complicated by the possibility
        // of duplicates in one or both.

        // if right.used_numbers is larger than left.remaining_numbers - match is impossible
        if right.used.len() > left.remaining.len() {
            return None;
        }

        // Check each used_number to see if its in the remaining_numbers in turn:
        for n in &right.used {
            let del_idx = remaining.iter().position(|x| x == n)?;
            let del_num = remaining.remove(del_idx);
            used.push(del_num);
        }

        // Now we can be sure we've only used numbers that were available, and that
        // remaining_numbers and used_numbers are appropriately set
        let formula = format!("({} {} {})", left.formula, op, right.formula);
        let result = calculate(&formula)?;
        Some(Expression {
            formula,
            used,
            remaining,
            result,
        })
    }
}

enum ExtendResult {
    Expressions(HashSet<Expression>),
    Answer(Expression),
    Nothing,
}

fn extend_expression(
    left: &Expression,
    li: usize,
    ops: &str,
    target: usize,
    expressions: &BTreeSet<Expression>,
) -> ExtendResult {
    let mut extended: HashSet<Expression> = HashSet::new();
    for op in ops.chars() {
        for (ri, right) in expressions.iter().enumerate() {
            if li == ri {
                continue; // no self-joins
            }

            if right.formula == "1" && op == '/' {
                continue; // division by 1 is pointless
            }

            if let Some(e) = left.extend(op, right) {
                match e.result {
                    x if x == target => return ExtendResult::Answer(e),
                    _ => {
                        extended.insert(e);
                    }
                }
            }
        }
    }

    if extended.is_empty() {
        ExtendResult::Nothing
    } else {
        ExtendResult::Expressions(extended)
    }
}

#[wasm_bindgen]
#[must_use]
pub fn numbers(input: &str, target: usize, ops: &str) -> Option<String> {
    println!("Starting numbers with {input}, ops = {ops} and target {target}");

    // Parse the inputs into numbers
    let input: Vec<usize> = input
        .split(',')
        .map(str::parse)
        .map(Result::unwrap)
        .collect();

    // Seed the initial set of expressions with the individual numbers
    let mut expressions: BTreeSet<_> = input
        .iter()
        .map(|v| {
            let mut remaining = input.clone();
            let used_idx = remaining
                .iter()
                .position(|x| x == v)
                .expect("reality is broken");
            remaining.swap_remove(used_idx);

            Expression {
                formula: format!("{v}"),
                used: vec![*v],
                remaining,
                result: *v,
            }
        })
        .collect();

    let mut iteration = 0;
    let mut start_size = 0;
    while expressions.len() > start_size {
        start_size = expressions.len();
        iteration += 1;

        println!(
            "interation = {iteration}, expressions to extend = {}",
            expressions.len()
        );

        let mut new_expressions = HashSet::new();

        // Attempt to extend each expression (that is able to be extended)
        for (idx, exp) in expressions.iter().enumerate() {
            match extend_expression(exp, idx, ops, target, &expressions) {
                ExtendResult::Answer(e) => return Some(e.formula),
                ExtendResult::Expressions(e) => {
                    new_expressions.extend(e);
                }
                ExtendResult::Nothing => {}
            }
        }

        expressions.extend(new_expressions);
    }

    None
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

#[test]
fn test_numbers() {
    let ops = "+-/*";

    assert_eq!(numbers("1,2", 3, ops).expect("no result :("), "(1 + 2)");

    let res = numbers("3,4,5,6", 123, "+*").expect("no result :(");
    assert!(res.contains("(((4 * 5) * 6) + 3)"));

    assert_eq!(
        numbers("1,2,3,4,5,6", 123, ops).expect("no result :("),
        "(((4 * 5) * 6) + 3)"
    );

    assert_eq!(
        numbers("50,100,9,1,9,3", 727, ops).unwrap(),
        "(((100 + 9) * 3) + ((9 - 1) * 50))"
    );
}
