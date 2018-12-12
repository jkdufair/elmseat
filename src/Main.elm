port module Main exposing (Model, Msg(..), Post, decodePost, init, main, receivePost, submitPost, subscriptions, update, view)

import Browser
import Html exposing (Html, button, div, h1, img, input, li, text, ul)
import Html.Attributes exposing (id, placeholder, src, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D
import Json.Encode as E
import Task
import Time exposing (Zone, Month, toYear, toMonth, toDay, toHour, toMinute, utc, millisToPosix)


port receivePost : (E.Value -> msg) -> Sub msg



---- MODEL ----


type alias Post =
    { message : String
    , timestamp : Int
    }


type alias Model =
    { posts : List Post
    , postInProgress : String
    , zone: Zone
    }


init : ( Model, Cmd Msg )
init =
    ( { posts = [ { message = "Hello, world", timestamp = 0 } ]
      , postInProgress = ""
      , zone = utc
      }
    , Cmd.batch [replayPosts, Task.perform AdjustTimeZone Time.here]
    )



---- UPDATE ----


type Msg
    = NoOp
    | AddPost Post
    | PostInProgressChange String
    | SubmitPost
    | PostSubmitted (Result Http.Error String)
    | PostsReplayed (Result Http.Error (List Post))
    | AdjustTimeZone Time.Zone


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddPost p ->
            ( { model | posts = p :: model.posts }, Cmd.none )

        PostInProgressChange p ->
            ( { model | postInProgress = p }, Cmd.none )

        SubmitPost ->
            ( { model | postInProgress = "" }, submitPost model.postInProgress )

        PostSubmitted (Ok _) ->
            ( model, Cmd.none )

        PostSubmitted (Err _) ->
            ( model, Cmd.none )

        PostsReplayed (Ok posts) ->
            ( { model | posts = List.append posts model.posts }, Cmd.none )

        PostsReplayed (Err _) ->
            ( model, Cmd.none )

        AdjustTimeZone newZone ->
            ({ model | zone = newZone}, Cmd.none)

        NoOp ->
            ( model, Cmd.none )


submitPost : String -> Cmd Msg
submitPost postInProgress =
    Http.send PostSubmitted <|
        Http.post "https://elmseat.azurewebsites.net/api/messages" (postInProgress |> E.string |> Http.jsonBody) D.string


replayPosts : Cmd Msg
replayPosts =
    Http.send PostsReplayed <|
        Http.get "https://elmseat.azurewebsites.net/api/replayPosts" (D.list postDecoder)




---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    receivePost decodePost


postDecoder : D.Decoder Post
postDecoder =
    D.map2 Post
        (D.field "message" D.string)
        (D.field "_ts" D.int)


decodePost : E.Value -> Msg
decodePost p =
    let
        result =
            D.decodeValue postDecoder p
    in
    case result of
        Ok parsedPost ->
            AddPost parsedPost

        Err foo ->
            NoOp



---- VIEW ----


view : Model -> Html Msg
view model =
    div [ id "bg-treatment"]
        [ img [ src "/logo.svg" ] []
        , h1 [] [ text "Your Elm App is working!" ]
        , input [ placeholder "What do you think?", value model.postInProgress, onInput PostInProgressChange ] []
        , button [ onClick SubmitPost ] [ text "Submit" ]
        , ul [] <|
            (List.map <| 
                \p -> li [] [ text p.message, text ": ", text <| formatDate p.timestamp model.zone ]) <|
                List.sortWith postsDescending model.posts
        ]


postsDescending : Post -> Post -> Order
postsDescending a b =
    case compare a.timestamp b.timestamp of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT

formatDate : Int -> Zone -> String
formatDate seconds zone =
    let
        millis = millisToPosix (seconds * 1000)
        year = String.fromInt <| toYear zone millis
        month = toMonth zone millis
        day = String.fromInt <| toDay zone millis
        hour = toHour zone millis
        minute = String.pad 2 '0' <| String.fromInt <| toMinute zone millis
    in toEnglishMonth month ++ " " ++ day ++ ", " ++ year ++ " (" ++ (String.fromInt <| toTwelveHourTime hour) ++ ":" ++ minute ++ " " ++ toAmPm hour ++ ")"

toEnglishMonth : Month -> String
toEnglishMonth month =
  case month of
    Time.Jan -> "January"
    Time.Feb -> "February"
    Time.Mar -> "March"
    Time.Apr -> "April"
    Time.May -> "May"
    Time.Jun -> "June"
    Time.Jul -> "July"
    Time.Aug -> "August"
    Time.Sep -> "September"
    Time.Oct -> "October"
    Time.Nov -> "November"
    Time.Dec -> "December"

toTwelveHourTime : Int -> Int
toTwelveHourTime hour =
    let h = modBy 12 hour
    in if h == 0 then 12 else h

toAmPm : Int -> String
toAmPm hour =
    if hour < 12 then "AM" else "PM"

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
