open Geneweb
open Gwd_lib
open Gwxjg

let handler =
  { Gwd_lib.RequestHandler.defaultHandler
    with fallback = begin fun mode self conf base ->
        if mode = "SANDBOX" then begin
        let models = Gwxjg.Data.default_env conf base in
        failwith "SANDBOX mode not yet implemented"
        end else self.incorrect_request self conf base
    end
}

module Request = Request.Make (struct let handler = handler end)
module Main = GwDaemon.Make (Request)

let _ =
  Main.run ()
