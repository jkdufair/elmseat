port module Main exposing (Model, Msg(..), Post, decodePost, init, main, receivePost, submitPost, subscriptions, update, view)

import Browser
import Html exposing (Html, a, br, button, div, form, h1, h2, h3, h6, img, input, label, li, nav, p, span, strong, text, textarea, ul)
import Html.Attributes exposing (action, alt, attribute, class, enctype, for, href, id, method, name, placeholder, src, target, title, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as D
import Json.Encode as E
import Task
import Time exposing (Month, Zone, millisToPosix, toDay, toHour, toMinute, toMonth, toYear, utc)


port receivePost : (E.Value -> msg) -> Sub msg



---- MODEL ----


type alias Post =
    { message : String
    , timestamp : Int
    }


type alias Model =
    { posts : List Post
    , postInProgress : String
    , zone : Zone
    }


init : ( Model, Cmd Msg )
init =
    ( { posts = [ { message = "Hello, world", timestamp = 0 } ]
      , postInProgress = ""
      , zone = utc
      }
    , Cmd.batch [ replayPosts, Task.perform AdjustTimeZone Time.here ]
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
            ( { model | zone = newZone }, Cmd.none )

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
    div [ id "bg-treatment" ]
        [ header
        , subNav
        , mainContent model
        , footer
        ]


header : Html Msg
header =
    nav [ id "wrapper-all" ]
        [ div [ class "pure-g clearfix", id "wrapper-header" ]
            [ div [ class "pure-u-1", id "header" ]
                [ div [ class "wrapper" ]
                    [ a [ class "hotseat", href "#" ]
                        [ text "Hotseat" ]
                    , nav [ class "clearfix" ]
                        [ ul []
                            [ li [ class "admin-li" ]
                                [ label [ class "show-menu hover", for "show-menu" ]
                                    [ text "Admin Options" ]
                                , input [ id "show-menu", attribute "role" "button", type_ "checkbox" ]
                                    []
                                , ul [ class "navexpand", id "adminMenu" ]
                                    [ li []
                                        [ a [ href "#" ]
                                            [ text "Manage Polls" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Manage Topics" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Manage Spaces" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Reports" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Manage Admins" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Thought Relevancy" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Manage Trial Requests" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Logging" ]
                                        ]
                                    ]
                                ]
                            , li [ class "user-li" ]
                                [ label [ class "show-menu hover", for "user-menu" ]
                                    [ text "Jason K" ]
                                , input [ id "user-menu", attribute "role" "button", type_ "checkbox" ]
                                    []
                                , ul [ class "navexpand", id "userMenu" ]
                                    [ li []
                                        [ a [ href "#" ]
                                            [ text "My Thoughts" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "My Favorites" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Edit My Profile" ]
                                        ]
                                    , li []
                                        [ a [ href "#" ]
                                            [ text "Getting Started" ]
                                        ]
                                    , li []
                                        [ a [ class "icon-logout pad logout", href "#" ]
                                            [ text "Log Out" ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


subNav : Html Msg
subNav =
    div [ class "pure-g", id "subnav-wrapper" ]
        [ nav [ class "pure-u-1 clearfix" ]
            [ a [ class "icon-list pad back-btn", href "#", title "back to space" ]
                [ text "Janet's Timeless Void"
                ]
            ]
        , div [ class "clear" ] []
        ]


mainContent : Model -> Html Msg
mainContent model =
    div [ class "clearfix", id "content", attribute "role" "main" ]
        [ div [ class "wrapper pure-g-r" ]
            [ div [ class "pure-u-1-3", id "topic" ]
                [ div [ class "col-header" ]
                    [ h2 []
                        [ text "Topic" ]
                    , nav [ class "drop-sauce" ]
                        [ ul []
                            [ li []
                                [ span [ class "icon-cog parent" ]
                                    []
                                , ul []
                                    [ li []
                                        [ a [ class "icon-pencil pad", href "#" ]
                                            [ text "Edit Topic" ]
                                        ]
                                    , li []
                                        [ a [ class "icon-statistics pad", href "#" ]
                                            [ text "Edit                                            Polls" ]
                                        ]
                                    , li []
                                        [ a [ class "icon-user pad", href "#" ]
                                            [ text "Turn Anonymous Off" ]
                                        ]
                                    , li []
                                        [ a [ class "icon-eye-blocked pad", href "#" ]
                                            [ text "Hidden Thoughts" ]
                                        ]
                                    , li []
                                        [ a [ class "icon-comment pad", href "#" ]
                                            [ text "Enable                                            Word Cloud" ]
                                        ]
                                    , li [ class "break" ]
                                        []
                                    , li [ class "small" ]
                                        [ a [ class "icon-lock pad", href "#", id "lock-btn", title "Lock Topic" ]
                                            [ text "Lock Topic" ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    , a [ class "picView col-header-btn icon-image tipsy-n", href "#", id "picView-btn", title "Pic View" ]
                        [ span [ class "screenreader-only" ]
                            [ text "picture review" ]
                        ]
                    ]
                , div [ class "col-content" ]
                    [ a [ class "fav-topic icon-star fav-btn icon-btn tipsy-s ", href "#", title "Favorite Topic" ]
                        [ span [ class "screenreader-only" ]
                            [ text "toggle favorite" ]
                        ]
                    , h2 []
                        [ span [ class "icon-lock  tipsy-s", attribute "style" "display:none;", title "An instructor has locked this topic." ]
                            []
                        , text "Who is Chidi Anagony... Agmeno... Ariana Grande?"
                        ]
                    , h3 [ class "overflow" ]
                        [ text "I do have a stomachache. Why do I always have a stomachache?" ]
                    , form [ action "/Topic/SubmitThought", class "", enctype "multipart/form-data", id "SubmitThought", method "post" ]
                        [ input [ name "__RequestVerificationToken", type_ "hidden", value "F773wwS3BTNo03gZLGXXnylsNOPkKYCCBzsN0OiSfmytbKe1MGbt5EkW80FCFM-y-4X0dsoaJuOjhCh0_Dvd-3Malpn27757XFjosKbQ5GwbX8dpz2HVrSW_I7t6sa2_BuISjKamhR1Y_O1SRLZ9rQ2" ]
                            []
                        , input [ id "PostCreatedBy", name "PostCreatedBy", type_ "hidden", value "13127" ]
                            []
                        , input [ id "PostTopicID", name "PostTopicID", type_ "hidden", value "20688" ]
                            []
                        , div [ class "topicthought" ]
                            [ textarea [ attribute "aria-label" "input what do you think here.", attribute "cols" "40", id "PostDescription", name "PostDescription", placeholder "What do you think?", attribute "rows" "2", value model.postInProgress, onInput PostInProgressChange ]
                                []
                            , div [ class "clear" ]
                                []
                            , h6 [ class "charsleft", id "charsLeft" ]
                                [ text (String.fromInt (300 - (String.length model.postInProgress))) ]
                            , div [ class "clearfix", id "button_block", attribute "style" "margin:0 0 5px;" ]
                                [ a [ class "col-content-btn icon-paperclip tipsy-s seek", href "#", attribute "style" "margin:5px 5px 5px 0;", title "Attach a Pic" ]
                                    [ span [ class "screenreader-only" ]
                                        [ text "attach a picture" ]
                                    ]
                                , label [ for "PostAnonymous", title "Post Anoymous" ]
                                    [ input [ class "anonbox", id "PostAnonymous", name "PostAnonymous", attribute "style" "position:relative;", type_ "checkbox", value "true" ]
                                        []
                                    , text "Post as Anonymous                                "
                                    ]
                                , div [ class "upload hide" ]
                                    [ div [ class "clear" ]
                                        []
                                    , label [ for "topicUpload" ]
                                        [ text "Attach a Pic" ]
                                    , input [ id "PostImageFileName", name "PostImageFileName", type_ "hidden", value "" ]
                                        []
                                    , text "                                    "
                                    , input [ id "topicUpload", name "topicUpload", type_ "file" ]
                                        []
                                    , div [ id "preview" ]
                                        [ a [ href "#" ]
                                            [ img [ alt "Delete", class "creator-delete", src "/images/delete.png" ]
                                                []
                                            , text "                                        "
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    , div [ class "clear" ] []
                    , div []
                        [ input [ class "topic-submit", id "btnSubmit", type_ "submit", value "Submit", onClick SubmitPost ] []
                        , text "                            "
                        ]
                    ]
                , div [ id "socialbox" ]
                    [ p [ class "text icon-mobile pad" ]
                        [ text "Text M20688 to (765) 560-4177"
                        ]
                    ]
                ]
            , div [ class "pure-u-2-3", id "thoughts" ]
                [ div [ class "pure-g", id "search", attribute "style" "display:none;" ]
                    []
                , form [ action "/Topic/View/20688", attribute "category" "recent", class "submitReply", id "3072", method "post" ]
                    [ div [ class "col-header" ]
                        [ p [ class "col-header-num", id "totalthoughts" ]
                            [ text <| String.fromInt <| List.length model.posts ]
                        , h2 []
                            [ text "Submitted Thoughts" ]
                        ]
                    , ul [ class "pure-g", id "thought-tabs" ]
                        [ li [ class "current  pure-u-1-3", id "tabrecent" ]
                            [ a [ href "#", title "Fresh Thoughts" ]
                                [ text "Fresh Thoughts"
                                , br []
                                    []
                                , span [ class "subtitle" ]
                                    [ text "(Sort By New)" ]
                                ]
                            ]
                        , li [ class " pure-u-1-3", id "tabvoted" ]
                            [ a [ href "#", title "Hot Thoughts" ]
                                [ text "Hot Thoughts"
                                , br []
                                    []
                                , span [ class "subtitle" ]
                                    [ text "(Sort By Votes)" ]
                                ]
                            ]
                        , li [ class " pure-u-1-3", id "tabreplies" ]
                            [ a [ href "#", title "Deep Thoughts" ]
                                [ text "Deep Thoughts"
                                , br []
                                    []
                                , span [ class "subtitle" ]
                                    [ text "(Sort By Replies)" ]
                                ]
                            ]
                        ]
                    , div [ class "clear" ] []
                    , div [ class "question", id "thoughtloader", attribute "style" "text-align:center; display:none;" ]
                        [ div [ class "q-content" ]
                            [ img [ alt "Loading...", src "/images/loader-32-orange-white.gif", attribute "style" "padding:15px;" ]
                                []
                            , h2 []
                                [ text "Thinking about thoughts..." ]
                            ]
                        ]
                    , div [ class "thought-container", id "questions" ]
                        (List.map (\p -> postContent model p) (List.sortWith postsDescending model.posts))
                    ]
                ]
            ]
        ]


footer : Html Msg
footer =
    div [ id "wrapper-footer" ]
        [ div [ id "footer" ]
            [ div [ class "wrapper" ]
                [ p []
                    [ a [ class "purdue_footer", href "http://www.purdue.edu", target "_blank", title "Purdue University" ]
                        [ text "Purdue" ]
                    , a [ href "http://www.purdue.edu/purdue/disclaimer.html" ]
                        [ text "© 2018 Purdue University" ]
                    , text "| "
                    , a [ href "http://www.purdue.edu/purdue/ea_eou_statement.html" ]
                        [ text "An                        equal access/equal opportunity university" ]
                    , text "| Version 4.17.15 - Chlorine                    "
                    , br []
                        []
                    , text "Need help or have trouble accessing this page? "
                    , a [ href "mailto:tlt@purdue.edu" ]
                        [ text "Contact us" ]
                    , text ".                    "
                    , span []
                        [ br []
                            []
                        , text "View our "
                        , a [ href "#" ]
                            [ text "getting started guide" ]
                        , text "."
                        ]
                    , br []
                        []
                    , a [ href "#" ]
                        [ text "Privacy Policy" ]
                    ]
                ]
            ]
        ]


postContent : Model -> Post -> Html Msg
postContent model post =
    div [ class "question-replies", attribute "hs_postcreatedticks" "636392629978370000", attribute "hs_replycount" "0.636392629978370000", attribute "hs_votecount" "0.636392629978370000" ]
        [ div [ class "question", attribute "hs_postid" "496270", attribute "hs_replycount" "0" ]
            [ div [ class "q-content pure-u-1 clearfix" ]
                [ div [ class "q-vote clearfix" ]
                    [ a [ class "vote-btn ", href "#", title "thought has 0 vote. click to vote for this." ]
                        [ span [ attribute "aria-hidden" "true" ]
                            [ text "0 " ]
                        ]
                    , a [ class "feat-btn icon-btn icon-arrow-up3", href "#", attribute "style" "display:block;", title "Toggle Featured" ]
                        [ span [ class "screenreader-only" ]
                            [ text "Toggle                                                Featured" ]
                        ]
                    ]
                , div [ class "q-text" ]
                    [ h3 [ class "post-description" ]
                        [ text post.message ]
                    , p [ class "author" ]
                        [ strong []
                            [ text "Anonymous" ]
                        , a [ href "#" ]
                            [ span [ class "utctime" ]
                                [ text <| formatDate post.timestamp model.zone ]
                            ]
                        , text "from Hotseat"
                        ]
                    ]
                , div [ class "q-controls clearfix q-controls-admin" ]
                    [ a [ class "fav-post fav-btn icon-star icon-btn ", href "#", title "Toggle Favorite" ]
                        [ span [ class "screenreader-only" ]
                            [ text "Toggle Favorite" ]
                        ]
                    , a [ class "hide-btn icon-blocked icon-btn", href "#", title "Hide" ]
                        [ span [ class "screenreader-only" ]
                            [ text "Hide" ]
                        ]
                    ]
                , a [ class "reply-btn reply-btn-show ", href "#", title "open 0 replies" ]
                    [ span [ attribute "aria-hidden" "true", class "reply-num" ]
                        [ text "Reply" ]
                    ]
                ]
            ]
        , ul [ class "replies", attribute "style" "display:none;" ]
            []
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
        millis =
            millisToPosix (seconds * 1000)

        year =
            String.fromInt <| toYear zone millis

        month =
            toMonth zone millis

        day =
            String.fromInt <| toDay zone millis

        hour =
            toHour zone millis

        minute =
            String.pad 2 '0' <| String.fromInt <| toMinute zone millis
    in
    toEnglishMonth month ++ " " ++ day ++ ", " ++ year ++ " (" ++ (String.fromInt <| toTwelveHourTime hour) ++ ":" ++ minute ++ " " ++ toAmPm hour ++ ")"


toEnglishMonth : Month -> String
toEnglishMonth month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


toTwelveHourTime : Int -> Int
toTwelveHourTime hour =
    let
        h =
            modBy 12 hour
    in
    if h == 0 then
        12

    else
        h


toAmPm : Int -> String
toAmPm hour =
    if hour < 12 then
        "AM"

    else
        "PM"



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
