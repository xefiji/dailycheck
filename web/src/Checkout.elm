module Checkout exposing (..)

import Browser
import Date exposing (Date)
import Debug
import Html exposing (Html, button, div, h2, input, label)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Result
import String exposing (replace)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Task
import Time exposing (Month(..))
import Toasty


type alias Flags =
    { url : String
    , title : String
    }


type alias Config =
    { url : String
    , title : String
    }


type alias Day =
    { day : String
    , dayReadable : String
    , sleep : Int
    , energy : Int
    , intellect : Int
    , serenity : Int
    , family : Int
    , social : Int
    , work : Int
    }


type alias Model =
    { day : Day
    , config : Config
    , toasties : Toasty.Stack String
    }


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        config =
            { url = replace "\\" "" flags.url |> replace "\"" ""
            , title = replace "\\" "" flags.title |> replace "\"" ""
            }
    in
    ( { day =
            { day = defaultDate |> Date.toIsoString
            , dayReadable = ""
            , sleep = 0
            , energy = 0
            , intellect = 0
            , serenity = 0
            , family = 0
            , social = 0
            , work = 0
            }
      , config = config
      , toasties = Toasty.initialState
      }
    , Cmd.batch
        [ Date.today |> Task.perform ReceiveDay
        ]
    )


defaultDate : Date
defaultDate =
    Date.fromCalendarDate 2022 Jan 1


fetchData : Config -> String -> String -> Cmd Msg
fetchData config memberId day =
    Http.get
        { url = config.url ++ memberId ++ "/day/" ++ day
        , expect = Http.expectJson DayReceived dayDecoder
        }


postData : Config -> String -> Day -> Cmd Msg
postData config id day =
    Http.post
        { url = config.url ++ id ++ "/day"
        , body = Http.jsonBody (newDayEncoder day)
        , expect = Http.expectJson DayCreated dayDecoder
        }


type Msg
    = UpdateSleep String
    | UpdateEnergy String
    | UpdateIntellect String
    | UpdateSerenity String
    | UpdateFamily String
    | UpdateSocial String
    | UpdateWork String
    | ResetRow String
    | ReceiveDay Date
    | FetchPreviousDay
    | FetchNextDay
    | DayReceived (Result Http.Error Day)
    | DayCreated (Result Http.Error Day)
    | ToastyMsg (Toasty.Msg String)
    | Submit


dayDecoder : Decoder Day
dayDecoder =
    Decode.succeed Day
        |> required "day" Decode.string
        |> required "day_readable" Decode.string
        |> required "sleep" Decode.int
        |> required "energy" Decode.int
        |> required "intellect" Decode.int
        |> required "serenity" Decode.int
        |> required "family" Decode.int
        |> required "social" Decode.int
        |> required "work" Decode.int


newDayEncoder : Day -> Encode.Value
newDayEncoder day =
    Encode.object
        [ ( "day", Encode.string day.day )
        , ( "sleep", Encode.int day.sleep )
        , ( "energy", Encode.int day.energy )
        , ( "intellect", Encode.int day.intellect )
        , ( "serenity", Encode.int day.serenity )
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

        "serenity" ->
            { day | serenity = value }

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
            ( { model | day = updateDayAttribute model.day attribute 0 }, Cmd.none )

        UpdateSleep value ->
            ( { model | day = updateDayAttribute model.day "sleep" (getValOrDefault value) }, Cmd.none )

        UpdateEnergy value ->
            ( { model | day = updateDayAttribute model.day "energy" (getValOrDefault value) }, Cmd.none )

        UpdateIntellect value ->
            ( { model | day = updateDayAttribute model.day "intellect" (getValOrDefault value) }, Cmd.none )

        UpdateSerenity value ->
            ( { model | day = updateDayAttribute model.day "serenity" (getValOrDefault value) }, Cmd.none )

        UpdateFamily value ->
            ( { model | day = updateDayAttribute model.day "family" (getValOrDefault value) }, Cmd.none )

        UpdateSocial value ->
            ( { model | day = updateDayAttribute model.day "social" (getValOrDefault value) }, Cmd.none )

        UpdateWork value ->
            ( { model | day = updateDayAttribute model.day "work" (getValOrDefault value) }, Cmd.none )

        ReceiveDay day ->
            let
                dayToUpdate =
                    model.day

                formattedDay =
                    Date.toIsoString day
            in
            ( { model | day = { dayToUpdate | day = formattedDay } }
            , fetchData model.config "955d5e0e-98a0-48d1-9ec4-18ce15026705" formattedDay
            )

        FetchPreviousDay ->
            ( model
            , fetchData model.config "955d5e0e-98a0-48d1-9ec4-18ce15026705" (addDays -1 model.day.day)
            )

        FetchNextDay ->
            ( model
            , fetchData model.config "955d5e0e-98a0-48d1-9ec4-18ce15026705" (addDays 1 model.day.day)
            )

        Submit ->
            ( model
            , postData model.config "955d5e0e-98a0-48d1-9ec4-18ce15026705" model.day
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


addDays : Int -> String -> String
addDays days ymd =
    let
        date =
            Date.fromIsoString ymd |> Result.withDefault defaultDate
    in
    Date.add Date.Days days date
        |> Date.toIsoString


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
    div []
        [ div [ Attr.class "navbar", Attr.class "navbar-light", Attr.class "fixed-top", Attr.class "bg-light" ]
            [ div [ Attr.class "container-fluid" ]
                [ Html.a [ Attr.class "navbar-brand" ]
                    [ Html.text (model.config.title ++ " " ++ model.day.dayReadable)
                    ]
                , Html.div [ Attr.id "prevNext" ]
                    [ Html.a
                        [ Attr.class "link-dark"
                        , Events.onClick FetchPreviousDay
                        ]
                        [ Html.i [ Attr.class "bi", Attr.class "bi-arrow-left-circle" ] []
                        ]
                    , Html.a
                        [ Attr.class "link-dark"
                        , Events.onClick FetchNextDay
                        ]
                        [ Html.i [ Attr.class "bi", Attr.class "bi-arrow-right-circle" ] []
                        ]
                    ]
                ]
            ]
        , div [ Attr.class "container", Attr.id "container-main" ]
            [ div [ Attr.class "rate" ]
                [ div [ Attr.class "toast-container" ]
                    [ Toasty.view toastyConfig renderToast ToastyMsg model.toasties
                    ]
                , renderRatingRow "sleep" model.day.sleep UpdateSleep
                , renderRatingRow "energy" model.day.energy UpdateEnergy
                , renderRatingRow "intellect" model.day.intellect UpdateIntellect
                , renderRatingRow "serenity" model.day.serenity UpdateSerenity
                , renderRatingRow "family" model.day.family UpdateFamily
                , renderRatingRow "social" model.day.social UpdateSocial
                , renderRatingRow "work" model.day.work UpdateWork
                ]
            , div [ Attr.class "submit" ]
                [ button
                    [ Events.onClick Submit
                    , Attr.class "btn"
                    , Attr.class "btn-success"
                    ]
                    [ Html.i [ Attr.class "bi", Attr.class "bi-check" ] []
                    , Html.text "All set!"
                    ]
                ]
            ]
        ]


renderToast : String -> Html Msg
renderToast toast =
    div [ Attr.class "alert", Attr.class "alert-primary" ] [ Html.text toast ]


renderRatingRow : String -> Int -> (String -> Msg) -> Html Msg
renderRatingRow name val event =
    div [ Attr.class "rating_container" ]
        [ div [ Attr.class "feedback" ]
            [ h2 [] [ Html.text name ]
            , div [ Attr.class "rating" ]
                [ input
                    [ Attr.type_ "radio"
                    , Attr.name name
                    , Attr.value <| String.fromInt 5
                    , Attr.checked (val == 5)
                    , Attr.id (name ++ "-5")
                    , Attr.class "star-5"
                    , Events.onInput event
                    ]
                    []
                , label [ Attr.for (name ++ "-5") ] []
                , input
                    [ Attr.type_ "radio"
                    , Attr.name name
                    , Attr.value <| String.fromInt 4
                    , Attr.checked (val == 4)
                    , Attr.id (name ++ "-4")
                    , Attr.class "star-4"
                    , Events.onInput event
                    ]
                    []
                , label [ Attr.for (name ++ "-4") ] []
                , input
                    [ Attr.type_ "radio"
                    , Attr.name name
                    , Attr.value <| String.fromInt 3
                    , Attr.checked (val == 3)
                    , Attr.id (name ++ "-3")
                    , Attr.class "star-3"
                    , Events.onInput event
                    ]
                    []
                , label [ Attr.for (name ++ "-3") ] []
                , input
                    [ Attr.type_ "radio"
                    , Attr.name name
                    , Attr.value <| String.fromInt 2
                    , Attr.checked (val == 2)
                    , Attr.id (name ++ "-2")
                    , Attr.class "star-2"
                    , Events.onInput event
                    ]
                    []
                , label [ Attr.for (name ++ "-2") ] []
                , input
                    [ Attr.type_ "radio"
                    , Attr.name name
                    , Attr.value <| String.fromInt 1
                    , Attr.checked (val == 1)
                    , Attr.id (name ++ "-1")
                    , Attr.class "star-1"
                    , if val == 1 then
                        Events.onClick (ResetRow name)

                      else
                        Events.onInput event
                    ]
                    []
                , label [ Attr.for (name ++ "-1") ] []
                , div [ Attr.class "emoji-wrapper" ]
                    [ div [ Attr.class "emoji" ]
                        [ svg [ Svg.Attributes.class "rating-0", viewBox "0 0 512 512" ] [ circle [ cx "256", cy "256", r "256", fill "#ffd93b" ] [], Svg.path [ d "M512 256c0 141.44-114.64 256-256 256-80.48 0-152.32-37.12-199.28-95.28 43.92 35.52 99.84 56.72 160.72 56.72 141.36 0 256-114.56 256-256 0-60.88-21.2-116.8-56.72-160.72C474.8 103.68 512 175.52 512 256z", fill "#f4c534" ] [], ellipse [ transform "scale(-1) rotate(31.21 715.433 -595.455)", cx "166.318", cy "199.829", rx "56.146", ry "56.13", fill "#fff" ] [], ellipse [ transform "rotate(-148.804 180.87 175.82)", cx "180.871", cy "175.822", rx "28.048", ry "28.08", fill "#3e4347" ] [], ellipse [ transform "rotate(-113.778 194.434 165.995)", cx "194.433", cy "165.993", rx "8.016", ry "5.296", fill "#5a5f63" ] [], ellipse [ transform "scale(-1) rotate(31.21 715.397 -1237.664)", cx "345.695", cy "199.819", rx "56.146", ry "56.13", fill "#fff" ] [], ellipse [ transform "rotate(-148.804 360.25 175.837)", cx "360.252", cy "175.84", rx "28.048", ry "28.08", fill "#3e4347" ] [], ellipse [ transform "scale(-1) rotate(66.227 254.508 -573.138)", cx "373.794", cy "165.987", rx "8.016", ry "5.296", fill "#5a5f63" ] [], Svg.path [ d "M370.56 344.4c0 7.696-6.224 13.92-13.92 13.92H155.36c-7.616 0-13.92-6.224-13.92-13.92s6.304-13.92 13.92-13.92h201.296c7.696.016 13.904 6.224 13.904 13.92z", fill "#3e4347" ] [] ]
                        , svg [ Svg.Attributes.class "rating-1", viewBox "0 0 512 512" ] [ circle [ cx "256", cy "256", r "256", fill "#ffd93b" ] [], Svg.path [ d "M512 256A256 256 0 0 1 56.7 416.7a256 256 0 0 0 360-360c58.1 47 95.3 118.8 95.3 199.3z", fill "#f4c534" ] [], Svg.path [ d "M328.4 428a92.8 92.8 0 0 0-145-.1 6.8 6.8 0 0 1-12-5.8 86.6 86.6 0 0 1 84.5-69 86.6 86.6 0 0 1 84.7 69.8c1.3 6.9-7.7 10.6-12.2 5.1z", fill "#3e4347" ] [], Svg.path [ d "M269.2 222.3c5.3 62.8 52 113.9 104.8 113.9 52.3 0 90.8-51.1 85.6-113.9-2-25-10.8-47.9-23.7-66.7-4.1-6.1-12.2-8-18.5-4.2a111.8 111.8 0 0 1-60.1 16.2c-22.8 0-42.1-5.6-57.8-14.8-6.8-4-15.4-1.5-18.9 5.4-9 18.2-13.2 40.3-11.4 64.1z", fill "#f4c534" ] [], Svg.path [ d "M357 189.5c25.8 0 47-7.1 63.7-18.7 10 14.6 17 32.1 18.7 51.6 4 49.6-26.1 89.7-67.5 89.7-41.6 0-78.4-40.1-82.5-89.7A95 95 0 0 1 298 174c16 9.7 35.6 15.5 59 15.5z", fill "#fff" ] [], Svg.path [ d "M396.2 246.1a38.5 38.5 0 0 1-38.7 38.6 38.5 38.5 0 0 1-38.6-38.6 38.6 38.6 0 1 1 77.3 0z", fill "#3e4347" ] [], Svg.path [ d "M380.4 241.1c-3.2 3.2-9.9 1.7-14.9-3.2-4.8-4.8-6.2-11.5-3-14.7 3.3-3.4 10-2 14.9 2.9 4.9 5 6.4 11.7 3 15z", fill "#fff" ] [], Svg.path [ d "M242.8 222.3c-5.3 62.8-52 113.9-104.8 113.9-52.3 0-90.8-51.1-85.6-113.9 2-25 10.8-47.9 23.7-66.7 4.1-6.1 12.2-8 18.5-4.2 16.2 10.1 36.2 16.2 60.1 16.2 22.8 0 42.1-5.6 57.8-14.8 6.8-4 15.4-1.5 18.9 5.4 9 18.2 13.2 40.3 11.4 64.1z", fill "#f4c534" ] [], Svg.path [ d "M155 189.5c-25.8 0-47-7.1-63.7-18.7-10 14.6-17 32.1-18.7 51.6-4 49.6 26.1 89.7 67.5 89.7 41.6 0 78.4-40.1 82.5-89.7A95 95 0 0 0 214 174c-16 9.7-35.6 15.5-59 15.5z", fill "#fff" ] [], Svg.path [ d "M115.8 246.1a38.5 38.5 0 0 0 38.7 38.6 38.5 38.5 0 0 0 38.6-38.6 38.6 38.6 0 1 0-77.3 0z", fill "#3e4347" ] [], Svg.path [ d "M131.6 241.1c3.2 3.2 9.9 1.7 14.9-3.2 4.8-4.8 6.2-11.5 3-14.7-3.3-3.4-10-2-14.9 2.9-4.9 5-6.4 11.7-3 15z", fill "#fff" ] [] ]
                        , svg [ Svg.Attributes.class "rating-2", viewBox "0 0 512 512" ] [ circle [ cx "256", cy "256", r "256", fill "#ffd93b" ] [], Svg.path [ d "M512 256A256 256 0 0 1 56.7 416.7a256 256 0 0 0 360-360c58.1 47 95.3 118.8 95.3 199.3z", fill "#f4c534" ] [], Svg.path [ d "M336.6 403.2c-6.5 8-16 10-25.5 5.2a117.6 117.6 0 0 0-110.2 0c-9.4 4.9-19 3.3-25.6-4.6-6.5-7.7-4.7-21.1 8.4-28 45.1-24 99.5-24 144.6 0 13 7 14.8 19.7 8.3 27.4z", fill "#3e4347" ] [], Svg.path [ d "M276.6 244.3a79.3 79.3 0 1 1 158.8 0 79.5 79.5 0 1 1-158.8 0z", fill "#fff" ] [], circle [ cx "340", cy "260.4", r "36.2", fill "#3e4347" ] [], g [ fill "#fff" ] [ ellipse [ transform "rotate(-135 326.4 246.6)", cx "326.4", cy "246.6", rx "6.5", ry "10" ] [], Svg.path [ d "M231.9 244.3a79.3 79.3 0 1 0-158.8 0 79.5 79.5 0 1 0 158.8 0z" ] [] ], circle [ cx "168.5", cy "260.4", r "36.2", fill "#3e4347" ] [], ellipse [ transform "rotate(-135 182.1 246.7)", cx "182.1", cy "246.7", rx "10", ry "6.5", fill "#fff" ] [] ]
                        , svg [ Svg.Attributes.class "rating-3", viewBox "0 0 512 512" ] [ circle [ cx "256", cy "256", r "256", fill "#ffd93b" ] [], Svg.path [ d "M407.7 352.8a163.9 163.9 0 0 1-303.5 0c-2.3-5.5 1.5-12 7.5-13.2a780.8 780.8 0 0 1 288.4 0c6 1.2 9.9 7.7 7.6 13.2z", fill "#3e4347" ] [], Svg.path [ d "M512 256A256 256 0 0 1 56.7 416.7a256 256 0 0 0 360-360c58.1 47 95.3 118.8 95.3 199.3z", fill "#f4c534" ] [], g [ fill "#fff" ] [ Svg.path [ d "M115.3 339c18.2 29.6 75.1 32.8 143.1 32.8 67.1 0 124.2-3.2 143.2-31.6l-1.5-.6a780.6 780.6 0 0 0-284.8-.6z" ] [], ellipse [ cx "356.4", cy "205.3", rx "81.1", ry "81" ] [] ], ellipse [ cx "356.4", cy "205.3", rx "44.2", ry "44.2", fill "#3e4347" ] [], g [ fill "#fff" ] [ ellipse [ transform "scale(-1) rotate(45 454 -906)", cx "375.3", cy "188.1", rx "12", ry "8.1" ] [], ellipse [ cx "155.6", cy "205.3", rx "81.1", ry "81" ] [] ], ellipse [ cx "155.6", cy "205.3", rx "44.2", ry "44.2", fill "#3e4347" ] [], ellipse [ transform "scale(-1) rotate(45 454 -421.3)", cx "174.5", cy "188", rx "12", ry "8.1", fill "#fff" ] [] ]
                        , svg [ Svg.Attributes.class "rating-4", viewBox "0 0 512 512" ] [ circle [ cx "256", cy "256", r "256", fill "#ffd93b" ] [], Svg.path [ d "M512 256A256 256 0 0 1 56.7 416.7a256 256 0 0 0 360-360c58.1 47 95.3 118.8 95.3 199.3z", fill "#f4c534" ] [], Svg.path [ d "M232.3 201.3c0 49.2-74.3 94.2-74.3 94.2s-74.4-45-74.4-94.2a38 38 0 0 1 74.4-11.1 38 38 0 0 1 74.3 11.1z", fill "#e24b4b" ] [], Svg.path [ d "M96.1 173.3a37.7 37.7 0 0 0-12.4 28c0 49.2 74.3 94.2 74.3 94.2C80.2 229.8 95.6 175.2 96 173.3z", fill "#d03f3f" ] [], Svg.path [ d "M215.2 200c-3.6 3-9.8 1-13.8-4.1-4.2-5.2-4.6-11.5-1.2-14.1 3.6-2.8 9.7-.7 13.9 4.4 4 5.2 4.6 11.4 1.1 13.8z", fill "#fff" ] [], Svg.path [ d "M428.4 201.3c0 49.2-74.4 94.2-74.4 94.2s-74.3-45-74.3-94.2a38 38 0 0 1 74.4-11.1 38 38 0 0 1 74.3 11.1z", fill "#e24b4b" ] [], Svg.path [ d "M292.2 173.3a37.7 37.7 0 0 0-12.4 28c0 49.2 74.3 94.2 74.3 94.2-77.8-65.7-62.4-120.3-61.9-122.2z", fill "#d03f3f" ] [], Svg.path [ d "M411.3 200c-3.6 3-9.8 1-13.8-4.1-4.2-5.2-4.6-11.5-1.2-14.1 3.6-2.8 9.7-.7 13.9 4.4 4 5.2 4.6 11.4 1.1 13.8z", fill "#fff" ] [], Svg.path [ d "M381.7 374.1c-30.2 35.9-75.3 64.4-125.7 64.4s-95.4-28.5-125.8-64.2a17.6 17.6 0 0 1 16.5-28.7 627.7 627.7 0 0 0 218.7-.1c16.2-2.7 27 16.1 16.3 28.6z", fill "#3e4347" ] [], Svg.path [ d "M256 438.5c25.7 0 50-7.5 71.7-19.5-9-33.7-40.7-43.3-62.6-31.7-29.7 15.8-62.8-4.7-75.6 34.3 20.3 10.4 42.8 17 66.5 17z", fill "#e24b4b" ] [] ]
                        , svg [ Svg.Attributes.class "rating-5", viewBox "0 0 512 512" ] [ g [ fill "#ffd93b" ] [ circle [ cx "256", cy "256", r "256" ] [], Svg.path [ d "M512 256A256 256 0 0 1 56.8 416.7a256 256 0 0 0 360-360c58 47 95.2 118.8 95.2 199.3z" ] [] ], Svg.path [ d "M512 99.4v165.1c0 11-8.9 19.9-19.7 19.9h-187c-13 0-23.5-10.5-23.5-23.5v-21.3c0-12.9-8.9-24.8-21.6-26.7-16.2-2.5-30 10-30 25.5V261c0 13-10.5 23.5-23.5 23.5h-187A19.7 19.7 0 0 1 0 264.7V99.4c0-10.9 8.8-19.7 19.7-19.7h472.6c10.8 0 19.7 8.7 19.7 19.7z", fill "#e9eff4" ] [], Svg.path [ d "M204.6 138v88.2a23 23 0 0 1-23 23H58.2a23 23 0 0 1-23-23v-88.3a23 23 0 0 1 23-23h123.4a23 23 0 0 1 23 23z", fill "#45cbea" ] [], Svg.path [ d "M476.9 138v88.2a23 23 0 0 1-23 23H330.3a23 23 0 0 1-23-23v-88.3a23 23 0 0 1 23-23h123.4a23 23 0 0 1 23 23z", fill "#e84d88" ] [], g [ fill "#38c0dc" ] [ Svg.path [ d "M95.2 114.9l-60 60v15.2l75.2-75.2zM123.3 114.9L35.1 203v23.2c0 1.8.3 3.7.7 5.4l116.8-116.7h-29.3z" ] [] ], g [ fill "#d23f77" ] [ Svg.path [ d "M373.3 114.9l-66 66V196l81.3-81.2zM401.5 114.9l-94.1 94v17.3c0 3.5.8 6.8 2.2 9.8l121.1-121.1h-29.2z" ] [] ], Svg.path [ d "M329.5 395.2c0 44.7-33 81-73.4 81-40.7 0-73.5-36.3-73.5-81s32.8-81 73.5-81c40.5 0 73.4 36.3 73.4 81z", fill "#3e4347" ] [], Svg.path [ d "M256 476.2a70 70 0 0 0 53.3-25.5 34.6 34.6 0 0 0-58-25 34.4 34.4 0 0 0-47.8 26 69.9 69.9 0 0 0 52.6 24.5z", fill "#e24b4b" ] [], Svg.path [ d "M290.3 434.8c-1 3.4-5.8 5.2-11 3.9s-8.4-5.1-7.4-8.7c.8-3.3 5.7-5 10.7-3.8 5.1 1.4 8.5 5.3 7.7 8.6z", fill "#fff", opacity ".2" ] [] ]
                        ]
                    ]
                ]
            ]
        ]
