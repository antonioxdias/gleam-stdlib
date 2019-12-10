import gleam/list

// Internal private representation of an Iterator

enum Action(element) {
  // Improper dancing in the middle of the street
  // Improper dancing in the middle of the street
  // Improper dancing in the middle of the street
  // Somebody better notify the chief of police
  Stop
  Continue(element, fn() -> Action(element))
  // Yes!
}

// Wrapper to hide the internal representation

pub external type Iterator(element);

// TODO: remove once we have opaque type wrappers
external fn opaque(fn() -> Action(element)) -> Iterator(element)
  = "gleam@iterator" "identity"

external fn unopaque(Iterator(element)) -> fn() -> Action(element)
  = "gleam@iterator" "identity"

pub fn identity(x) {
  x
}

// Public API for iteration

pub enum Step(element, acc) {
  Next(element, acc)
  Done
}

// Creating Iterators

fn do_unfold(initial, f) {
  fn() {
    case f(initial) {
      Next(x, acc) -> Continue(x, do_unfold(acc, f))
      Done -> Stop
    }
  }
}

// TODO: test
// TODO: document
pub fn unfold(from initial: acc, with f: fn(acc) -> Step(element, acc)) -> Iterator(element) {
  opaque(do_unfold(initial, f))
}

// TODO: test
// TODO: document
pub fn repeatedly(f: fn() -> element) -> Iterator(element) {
  unfold(Nil, fn(acc) { Next(f(), acc) })
}

// TODO: test
// TODO: document
pub fn repeat(x: element) -> Iterator(element) {
  repeatedly(fn() { x })
}

// TODO: test
// TODO: document
pub fn from_list(list: List(element)) -> Iterator(element) {
  unfold(list, fn(acc) {
    case acc {
      [] -> Done
      [head | tail] -> Next(head, tail)
    }
  })
}

// Consuming Iterators

fn do_fold(iterator, initial, f) {
  case iterator() {
    Continue(element, iterator) -> do_fold(iterator, f(element, initial), f)
    Stop -> initial
  }
}

// TODO: test
// TODO: document
pub fn fold(over iterator: Iterator(e), from initial: acc, with f: fn(e, acc) -> acc) -> acc {
  do_fold(unopaque(iterator), initial, f)
}

// TODO: test
// TODO: document
// For side effects
pub fn run(iterator) -> Nil {
  fold(iterator, Nil, fn(_, acc) { acc })
}

// TODO: test
// TODO: document
pub fn to_list(iterator: Iterator(element)) -> List(element) {
  iterator
  |> fold(_, [], fn(e, acc) { [e | acc] })
  |> list.reverse
}

// Transforming Iterators

fn do_map(iterator, f) {
  fn() {
    case iterator() {
      Continue(e, iterator) -> Continue(f(e), do_map(iterator, f))
      Stop -> Stop
    }
  }
}

// TODO: test
// TODO: document
pub fn map(over iterator: Iterator(a), with f: fn(a) -> b) -> Iterator(b) {
  opaque(do_map(unopaque(iterator), f))
}

fn do_filter(iterator, predicate) {
  fn() {
    case iterator() {
      Continue(e, iterator) -> case predicate(e) {
        True -> Continue(e, iterator)
        False -> do_filter(iterator, predicate)()
      }
      Stop -> Stop
    }
  }
}

// TODO: test
// TODO: document
pub fn filter(iterator: Iterator(a), for predicate: fn(a) -> Bool) -> Iterator(a) {
  opaque(do_filter(unopaque(iterator), predicate))
}