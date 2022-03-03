module Checkout exposing (..)

import Browser
import Date exposing (Date)
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
import Json.Encode as Encode
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
            , sleep = -1
            , energy = -1
            , intellect = -1
            , anxiety = -1
            , family = -1
            , social = -1
            , work = -1
            }
    in
    ( { day = day
      , toasties = Toasty.initialState
      }
    , Cmd.batch
        [ Date.today |> Task.perform ReceiveDay
        , fetchData "955d5e0e-98a0-48d1-9ec4-18ce15026705"
        ]
    )


fetchData : String -> Cmd Msg
fetchData id =
    Http.get
        { url = url id
        , expect = Http.expectJson DayReceived dayDecoder
        }


postData : String -> Day -> Cmd Msg
postData id day =
    Http.post
        { url = url id
        , body = Http.jsonBody (newDayEncoder day)
        , expect = Http.expectJson DayCreated dayDecoder
        }


url : String -> String
url id =
    "http://dailycheck.fxechappe.com/member/" ++ id ++ "/day"


type Msg
    = UpdateSleep String
    | UpdateEnergy String
    | UpdateIntellect String
    | UpdateAnxiety String
    | UpdateFamily String
    | UpdateSocial String
    | UpdateWork String
    | ResetRow String
    | ReceiveDay Date
    | DayReceived (Result Http.Error Day)
    | DayCreated (Result Http.Error Day)
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


newDayEncoder : Day -> Encode.Value
newDayEncoder day =
    Encode.object
        [ ( "day", Encode.string day.day )
        , ( "sleep", Encode.int day.sleep )
        , ( "energy", Encode.int day.energy )
        , ( "intellect", Encode.int day.intellect )
        , ( "anxiety", Encode.int day.anxiety )
        , ( "family", Encode.int day.family )
        , ( "social", Encode.int day.social )
        , ( "work", Encode.int day.work )
        ]


updateDayAttribute : Day -> String -> Int -> Day
updateDayAttribute day attribute value =
    case attribute of
        "sleep" ->
            { day | sleep = value }

        "energy" ->
            { day | energy = value }

        "intellect" ->
            { day | intellect = value }

        "anxiety" ->
            { day | anxiety = value }

        "family" ->
            { day | family = value }

        "social" ->
            { day | social = value }

        "work" ->
            { day | work = value }

        _ ->
            day


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ResetRow attribute ->
            ( { model | day = updateDayAttribute model.day attribute -1 }, Cmd.none )

        UpdateSleep value ->
            ( { model | day = updateDayAttribute model.day "sleep" (getValOrDefault value) }, Cmd.none )

        UpdateEnergy value ->
            ( { model | day = updateDayAttribute model.day "energy" (getValOrDefault value) }, Cmd.none )

        UpdateIntellect value ->
            ( { model | day = updateDayAttribute model.day "intellect" (getValOrDefault value) }, Cmd.none )

        UpdateAnxiety value ->
            ( { model | day = updateDayAttribute model.day "anxiety" (getValOrDefault value) }, Cmd.none )

        UpdateFamily value ->
            ( { model | day = updateDayAttribute model.day "family" (getValOrDefault value) }, Cmd.none )

        UpdateSocial value ->
            ( { model | day = updateDayAttribute model.day "social" (getValOrDefault value) }, Cmd.none )

        UpdateWork value ->
            ( { model | day = updateDayAttribute model.day "work" (getValOrDefault value) }, Cmd.none )

        ReceiveDay today ->
            let
                dayToUpdate =
                    model.day
            in
            ( { model | day = { dayToUpdate | day = Date.toIsoString today } }, Cmd.none )

        Submit ->
            ( model
            , postData "955d5e0e-98a0-48d1-9ec4-18ce15026705" model.day
            )

        DayReceived (Ok day) ->
            ( { model
                | day = day
              }
            , Cmd.none
            )

        DayReceived (Err httpError) ->
            ( model
            , Cmd.none
            )
                |> Toasty.addToast toastyConfig ToastyMsg (buildErrorMessage httpError)

        DayCreated (Ok day) ->
            ( { model
                | day = day
              }
            , Cmd.none
            )
                |> Toasty.addToast toastyConfig ToastyMsg "successfully saved day"

        DayCreated (Err httpError) ->
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


viewStars : String -> Int -> (String -> Msg) -> Html Msg
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


viewLabel : Int -> String -> Html Msg
viewLabel index name =
    label [ Attr.for (name ++ String.fromInt index) ] [ text (name ++ String.fromInt index) ]


viewStar : Int -> String -> Int -> (String -> Msg) -> Html Msg
viewStar index name val event =
    input
        [ Attr.type_ "radio"
        , Attr.name name
        , Attr.value <| String.fromInt index
        , if index == 1 && val == 1 then
            Events.onClick (ResetRow name)

          else
            Events.onInput event
        , Attr.checked (val == index)
        , Attr.id (name ++ String.fromInt index)
        ]
        []


renderToast : String -> Html Msg
renderToast toast =
    div [] [ text toast ]
