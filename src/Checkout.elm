module Checkout exposing (..)

import Browser
import Date exposing (Date)
import Debug
import Html exposing (Html, button, div, h1, h2, h3, input, label, text)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Json.Decode as Decode
    exposing
        ( Decoder
        , int
        , string
        )
import Json.Decode.Pipeline exposing (required)
import Task
import Time exposing (Month(..))
import Toasty


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type alias Day =
    { day : String
    , sleep : Int
    , energy : Int
    , intellect : Int
    , anxiety : Int
    , family : Int
    , social : Int
    , work : Int
    }


type alias Model =
    { day : Day
    , toasties : Toasty.Stack String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        day =
            { day = Date.fromCalendarDate 2019 Jan 1 |> Date.toIsoString
            , sleep = 0
            , energy = 0
            , intellect = 0
            , anxiety = 0
            , family = 0
            , social = 0
            , work = 0
            }
    in
    ( { day = day
      , toasties = Toasty.initialState
      }
    , Cmd.batch
        [ Date.today |> Task.perform ReceiveDate
        , fetchData
        ]
    )


fetchData : Cmd Msg
fetchData =
    Http.get
        { url = url
        , expect = Http.expectJson ReceiveDatas dayDecoder
        }


url : String
url =
    "http://localhost:5016/daily-check.json"


type Msg
    = UpdateSleep String
    | UpdateEnergy String
    | UpdateIntellect String
    | UpdateAnxiety String
    | UpdateFamily String
    | UpdateSocial String
    | UpdateWork String
    | ReceiveDate Date
    | ReceiveDatas (Result Http.Error Day)
    | ToastyMsg (Toasty.Msg String)
    | Submit


dayDecoder : Decoder Day
dayDecoder =
    Decode.succeed Day
        |> required "day" string
        |> required "sleep" int
        |> required "energy" int
        |> required "intellect" int
        |> required "anxiety" int
        |> required "family" int
        |> required "social" int
        |> required "work" int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateSleep value ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | sleep = getValOrDefault value } }, Cmd.none )

        UpdateEnergy value ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | energy = getValOrDefault value } }, Cmd.none )

        UpdateIntellect value ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | intellect = getValOrDefault value } }, Cmd.none )

        UpdateAnxiety value ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | anxiety = getValOrDefault value } }, Cmd.none )

        UpdateFamily value ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | family = getValOrDefault value } }, Cmd.none )

        UpdateSocial value ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | social = getValOrDefault value } }, Cmd.none )

        UpdateWork value ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | work = getValOrDefault value } }, Cmd.none )

        ReceiveDate today ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | day = Date.toIsoString today } }, Cmd.none )

        Submit ->
            let
                _ =
                    Debug.log "model " model
            in
            ( model
            , Cmd.none
            )
                |> Toasty.addToast toastyConfig ToastyMsg "successfully saved day"

        ReceiveDatas (Ok day) ->
            let
                _ =
                    Debug.log "day " day
            in
            ( { model
                | day = day
              }
            , Cmd.none
            )

        ReceiveDatas (Err httpError) ->
            let
                _ =
                    Debug.log "error " httpError
            in
            ( model
            , Cmd.none
            )
                |> Toasty.addToast toastyConfig ToastyMsg (buildErrorMessage httpError)

        ToastyMsg subMsg ->
            Toasty.update toastyConfig ToastyMsg subMsg model


toastyConfig : Toasty.Config msg
toastyConfig =
    Toasty.config
        |> Toasty.transitionOutDuration 100
        |> Toasty.delay 8000


getValOrDefault : String -> Int
getValOrDefault val =
    String.toInt val
        |> Maybe.withDefault 0


buildErrorMessage : Http.Error -> String
buildErrorMessage httpError =
    case httpError of
        Http.BadUrl message ->
            message

        Http.Timeout ->
            "Server is taking too long to respond. Please try again later."

        Http.NetworkError ->
            "Unable to reach server."

        Http.BadStatus statusCode ->
            "Request failed with status code: " ++ String.fromInt statusCode

        Http.BadBody message ->
            message


view : Model -> Html Msg
view model =
    div [ Attr.class "container" ]
        [ div [ Attr.class "rate" ]
            [ h1 [] [ text "Daily Check" ]
            , h2 [] [ text model.day.day ]
            , Toasty.view toastyConfig renderToast ToastyMsg model.toasties
            , viewStars "sleep" model.day.sleep UpdateSleep
            , viewStars "energy" model.day.energy UpdateEnergy
            , viewStars "intellect" model.day.intellect UpdateIntellect
            , viewStars "anxiety" model.day.anxiety UpdateAnxiety
            , viewStars "family" model.day.family UpdateFamily
            , viewStars "social" model.day.social UpdateSocial
            , viewStars "work" model.day.work UpdateWork
            ]
        , div [ Attr.class "submit", Attr.class "row" ]
            [ div [ Attr.class "col-md-6" ]
                [ button
                    [ Events.onClick Submit
                    , Attr.class "btn"
                    , Attr.class "btn-success"
                    ]
                    [ text "All set!" ]
                ]
            ]
        ]


viewStars : String -> Int -> (String -> msg) -> Html msg
viewStars name val event =
    div [ Attr.class "row" ]
        [ div [ Attr.class "col-md-6" ]
            [ h3 [] [ text name ]
            , div [ Attr.class "stars" ]
                [ viewStar 5 name val event
                , viewLabel 5 name
                , viewStar 4 name val event
                , viewLabel 4 name
                , viewStar 3 name val event
                , viewLabel 3 name
                , viewStar 2 name val event
                , viewLabel 2 name
                , viewStar 1 name val event
                , viewLabel 1 name
                ]
            ]
        ]


viewLabel : Int -> String -> Html msg
viewLabel index name =
    label [ Attr.for (name ++ String.fromInt index) ] [ text (name ++ String.fromInt index) ]


viewStar : Int -> String -> Int -> (String -> msg) -> Html msg
viewStar index name val event =
    input
        [ Attr.type_ "radio"
        , Attr.name name
        , Attr.value <| String.fromInt index
        , Events.onInput event
        , Attr.checked (val == index)
        , Attr.id (name ++ String.fromInt index)
        ]
        []


renderToast : String -> Html Msg
renderToast toast =
    div [] [ text toast ]
