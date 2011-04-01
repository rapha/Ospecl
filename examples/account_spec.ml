#load "account.cmo";;

open Ospecl.Spec
open Ospecl.Matchers

let main = 
  let account_spec = 
    describe "An account" begin
      let empty = Account.create () in
      [
        it "initially has a balance of 0" begin
          expect (Account.balance empty) (is equal_to_int 0)
        end;
        describe "when depositing an amount" [
          it "is not changed in-place" begin
            ignore (Account.deposit 100 empty);
            expect (Account.balance empty) (is equal_to_int 0)
          end;
          describe "that is positive" [
            it "increases the balance by that amount" begin
              let to_deposit = 1 in
              let after_deposit = Account.deposit to_deposit empty in
              expect (Account.balance after_deposit) (is equal_to_int to_deposit)
            end;
            describe "multiple times" [
              it "increases the balance by the sum of those amounts" begin
                let to_deposit = [1;2;3;4] in
                let total_deposits = List.fold_left (+) 0 to_deposit in
                let after_deposits = List.fold_left (fun acct amt -> Account.deposit amt acct) empty to_deposit in
                expect (Account.balance after_deposits) (is equal_to_int total_deposits)
              end
            ]
          ];
          describe "that is negative" [
            it "fails" begin
              expect 
                (fun _ -> Account.deposit (-1) empty) 
                (raise_exn (Invalid_argument "Cannot deposit a negative amount: -1"))
            end
          ];
        ];
        describe "when withdrawing an amount" [
          describe "that is positive" [
            describe "but less than the current balance" [
              it "decreases the balance by that amount" begin
                let before = Account.deposit 100 empty in
                let after = Account.withdraw 50 before in
                expect
                  (Account.balance after)
                  (is equal_to_int (Account.balance before - 50))
              end;
            ];
            describe "and more than the current balance" [
              it "fails" begin
                expect 
                  (fun _ -> Account.withdraw 50 empty)
                  (raise_exn (Account.Insufficient_funds 0))
              end;
            ];
          ];
          describe "that is negative" [
            it "fails" begin
              expect
                (fun _ -> Account.withdraw (-1) empty)
                (raise_exn (Invalid_argument "Cannot withdraw a negative amount: -1"))
            end
          ]
        ]
      ]
    end
  in
  Ospecl.Run.console [account_spec]
