open OUnit2

let () = 
  run_test_tt_main (test_list [
    Polynomial_tests.polynomial_suite;
    Polynomial_tests.polymat_suite;
    Chat_encryption_tests.chat_encryption_suite;
    Kyber_tests.kyber_suite
  ])