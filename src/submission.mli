
val summate : int -> int
(** [summate n] is 0+1+2+...+n where [n] is non-negative. *)

val lcm : int -> int -> int
(** [lcm n m] is the least common multiple of [n] and [m]. *)

val fibonacci : int -> int
(** [fibonacci n] is the [n]-th fibonacci number. *)

val range : int -> int -> int list
(** [range a b] is the list [a..b-1] *)

val arithmetic_progression : int -> int -> int -> int list
(** [arithmetic_progression n d k] is the list [n; n + d; n + 2d; ...; n + (k-1)d], where [k] is non-negative. *)

val factors : int -> int list
(** [factors n] is all positive factors of [n]. *)

val reverse : 'a list -> 'a list
(** [reverse ls] is the list [ls] in reverse. *)

val is_ordered : string list -> bool
(** [is_ordered ls] is true if and only if [ls] is in sorted order. *)

val insert_string : string -> string list -> (string list, string) result
(** [insert_string s ls] is Ok of [ls] with [s] added if [ls] is ordered, otherwise is Error "insert into unordered list". *)

val insertion_sort : string list -> string list
(** [insertion_sort ls] is the list [ls] in sorted order using insertion sort. *)

val split_list : 'a list -> int -> 'a list * 'a list
(** [split_list ls n] is a tuple of the first [n] elements of [ls], and the remaining elements. *)

val merge_sort : int list -> int list
(** [merge_sort ls] is the list [ls] in sorted order using merge sort. *)