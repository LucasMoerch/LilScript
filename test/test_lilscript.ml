open OUnit2

let () =
  run_test_tt_main
    ("all"
    >::: [
           Test_lexer.suite;
           Test_typecheck.suite;
           Test_diagnostics.suite;
           Test_pipeline.suite;
           Test_codegen.suite;
           Test_acceptance.suite;
         ])
