module Job exposing (..)

import Html              exposing (..)
import Html.App
import Http
import Task
--import Time
import Json.Encode
import Json.Decode       exposing ((:=))
import Json.Decode.Extra exposing ((|:))

--import HttpBuilder       exposing (..)

import Widget.Data.Type  exposing (..)
import Widget.Data.Json
import Widget.Gen
import Widget
import Util.Debug
import RSyncConfig       exposing (..)



-- MODEL

type alias Model =
  { id           : String
  , name         : String
  , node         : Node
  , debug        : Util.Debug.Model
  , output       : String
  }

init : ( Model, Cmd msg )
init =
    let
--        node = aBool "11" "22" "33" "44"
        node = RSyncConfig.init
    in
        ( Model node.rec.id node.rec.label node Util.Debug.init ""
        , Cmd.none )


-- UPDATE

type Msg
  = Rename String
  | Save String
  | SaveSucceed Model
  | SaveFail Http.Error
  | WidgetMsg Widget.Msg
  | DebugMsg Util.Debug.Msg

--update : Msg -> { mdl | name : String } -> ( { mdl | name : String }, Cmd msg )
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Rename newName ->
      { model
      | name = newName
      } ! []

    WidgetMsg wm ->
        let
            (node', wm') = Widget.update wm model.node
        in
            { model
            | node = node'
            } ! [ Cmd.map WidgetMsg wm' ]

    Save jobTypeName ->
        let
            sljCmd = saveLoadJob jobTypeName model
            _ = Debug.log "Job.update:saveLoadJob" sljCmd
        in
            ( model, sljCmd )

    SaveSucceed newModel ->   -- Model ->
        newModel ! []
--        let
--          ( nCombo, nCbMsg ) =
--            ComboBox.update (ComboBox.Success saveResult.jobName) model.combo
--        in
--          { model
--          | combo = nCombo
--          , output = toString saveResult
--          , lastErr = Nothing
--          , lastOk = Just ( "job " ++ saveResult.jobName ++ " saved" )
--          } ! [ Cmd.map ComboMsg nCbMsg ]

    SaveFail err ->   -- Http.Error ->
        model ! []
--          { model
--          | output = toString err
--          , lastErr = Just err
--          , lastOk = Nothing
--          } ! []

    DebugMsg dbgMsg ->
        let
            ( newDebug, nDbgMsg ) = Util.Debug.update dbgMsg model.debug
        in
            { model
            | debug = newDebug
            } ! [ Cmd.map DebugMsg nDbgMsg ]


-- VIEW

view : String -> Model -> Html Msg
view jobTypeName model =
  div []
  [ table []
    [
--      tr []
--      [ th [] [ text jobTypeName ]
--      , td [] [ text model.name ]
--      ]
--    ,
      tr []
      [ td [] [ Html.App.map WidgetMsg (Widget.view model.node) ]
      ]
    , Html.App.map DebugMsg ( Util.Debug.viewDbgStr "Job" model.output model.debug )
    ]
  ]



-- Helpers

--saveLoadJob : String -> Model -> Cmd Msg
--saveLoadJob jobTypeName model =
--    saveLoadJobCall jobTypeName model
--        |> Task.perform SaveFail SaveSucceed

saveLoadJob : String -> Model -> Cmd Msg
saveLoadJob jobTypeName model =
  let
    _ = Debug.log "Job.saveLoadJob" model
  in
    saveLoadJobCall jobTypeName model
        |> Task.perform SaveFail SaveSucceed


--saveLoadJobCall : String -> Model -> Task.Task (HttpBuilder.Error String) (HttpBuilder.Response (Model))
saveLoadJobCall : String -> Model -> Task.Task Http.Error Model
saveLoadJobCall jobTypeName job =
--saveLoadJobCall jobTypeName job newJobId =
  let
    url = "/jobs/RSync"
    body_s =
--      initJob jobName model
      job
        |> encodeJob jobTypeName
        |> Json.Encode.encode 2
  in
    Http.post decodeJob url (Http.string body_s)

----saveLoadJobCall : Json.Decode.Decoder node -> String -> Model -> Task.Task (HttpBuilder.Error String) (HttpBuilder.Response (Model))
----saveLoadJobCall decodeNode jobTypeName job =
--saveLoadJobCall : String -> Model -> Task.Task (HttpBuilder.Error String) (HttpBuilder.Response (Model))
--saveLoadJobCall jobTypeName job =
--  HttpBuilder.post "/jobs/RSync"
--    |> withJsonBody (encodeJob jobTypeName job)
--    |> withHeader "Content-Type" "application/json"
--    |> withTimeout (10 * Time.second)
--    |> withCredentials
--    |> send (jsonReader (decodeJob)) stringReader


{----------------------------------------------}
--decodeJob : Json.Decode.Decoder node -> Json.Decode.Decoder Model
--decodeJob decodeNode =
decodeJob : Json.Decode.Decoder Model
decodeJob =
--  { id           : String
--  , name         : String
--  , node         : Node
--  , debug        : Util.Debug.Model
--  , output       : String
--  }
    Json.Decode.succeed Model
--        |: ("json_id"   := Json.Decode.string)
--        |: ("yaml_id"   := Json.Decode.string)
        |: ("id"        := Json.Decode.string)
        |: ("job_name"  := Json.Decode.string)
--        |: ("type_name" := Json.Decode.string)
--        |: ("cmd"       := Json.Decode.string)
--        |: ("root"      := decodeNode)
        |: ("root"      := Widget.Data.Json.decodeNode)
--        |: ("debug"     := Json.Decode.bool)
--        |: ("output"    := Json.Decode.string)
        |: Json.Decode.null Util.Debug.init            -- ("debug"     := Json.Decode.bool)
        |: Json.Decode.null ""                         -- ("output"    := Json.Decode.string)
----------------------------------------------}

--encodeJob : (node -> Json.Encode.Value) -> String -> Model -> Json.Encode.Value
--encodeJob encodeNode jobTypeName job =
encodeJob : String -> Model -> Json.Encode.Value
encodeJob jobTypeName job =
    Json.Encode.object
--        [ ("json_id",   Json.Encode.string job.jsonId)
--        , ("yaml_id",   Json.Encode.string job.yamlId)
        [ ("id",        Json.Encode.string job.id)
        , ("job_name",  Json.Encode.string job.name)
        , ("type_name", Json.Encode.string jobTypeName)
        , ("cmd",       Json.Encode.string <| Widget.Gen.cmdOf job.node)
--        , ("root",      encodeNode job.node)
        , ("root",      Widget.Data.Json.encodeNode job.node)
        ]