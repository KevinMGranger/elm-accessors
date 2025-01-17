module Spec exposing (suite)

import Test exposing (Test, describe, test)
import Expect
import Accessors exposing (get, set, over, makeOneToOne, makeOneToN)
import Accessors.Library exposing (onEach, try)
import Test.Accessors.Record exposing (r)


simpleRecord = {foo = 3, bar = "Yop", qux = False}
anotherRecord = {foo = 5, bar = "Sup", qux = True}
nestedRecord = {foo = simpleRecord}
recordWithList = {bar = [simpleRecord, anotherRecord]}
maybeRecord = {bar = Just simpleRecord, foo = Nothing}

suite : Test
suite =
  describe "working lenses"
    [ describe "get"
      [ test "simple get" <| \_ -> 
          Expect.equal 
            ( get r.foo simpleRecord)
            3
      , test "nested get" <| \_ ->
          Expect.equal
            (get (r.foo << r.bar) nestedRecord)
            "Yop"
      , test "get in list" <| \_ ->
          Expect.equal 
            (get (r.bar << onEach << r.foo) recordWithList)
            [3, 5]
      , test "get in Just" <| \_ ->
          Expect.equal
            (get (r.bar << try << r.qux) maybeRecord)
            (Just False)
      , test "get in Nothing" <| \_ ->
          Expect.equal
            (get (r.foo << try << r.bar) maybeRecord)
            Nothing
      ]
    , describe "set"
      [ test "simple set" <| \_ ->
          let updatedExample =
                (set r.qux True simpleRecord)
          in Expect.equal
            updatedExample.qux
            True
      , test "nested set" <| \_->
          let updatedExample = 
                (set (r.foo << r.foo) 5 nestedRecord)
          in Expect.equal
            updatedExample.foo.foo
            5
      , test "set in list" <| \_ -> 
          let updatedExample = 
                (set (r.bar << onEach << r.bar) "Why, hello" recordWithList)
          in Expect.equal
            (get (r.bar << onEach << r.bar) updatedExample)
            ["Why, hello", "Why, hello"]
      , test "set in Just" <| \_ ->
          let updatedExample = 
                (set (r.bar << try << r.foo) 4 maybeRecord)
          in Expect.equal
            (get (r.bar << try << r.foo) updatedExample)
            (Just 4)
      , test "set in Nothing" <| \_ ->
          let updatedExample = 
                (set (r.foo << try << r.bar) "Nope" maybeRecord)
          in Expect.equal
            (get (r.foo << try << r.bar) updatedExample)
            Nothing
      ]
    , describe "over"
      [ test "simple over" <| \_ ->
          let updatedExample =
                (over r.bar (\w -> w ++ " lait") simpleRecord)
          in Expect.equal
            updatedExample.bar
            "Yop lait"
      , test "nested over" <| \_ ->
          let updatedExample =
                (over (r.foo << r.qux) (\w -> not w) nestedRecord)
          in Expect.equal
            updatedExample.foo.qux
            True
      , test "over list" <| \_ -> 
          let updatedExample = 
                (over (r.bar << onEach << r.foo) (\n -> n-2) recordWithList)
          in Expect.equal
            (get (r.bar << onEach << r.foo) updatedExample)
            [1, 3]
      , test "over through Just" <| \_ ->
          let updatedExample = 
                (over (r.bar << try << r.foo) (\n -> n+3) maybeRecord)
          in Expect.equal
            (get (r.bar << try << r.foo) updatedExample)
            (Just 6)
      , test "over through Nothing" <| \_ ->
          let updatedExample = 
                (over (r.foo << try << r.bar) (\w -> w++"!") maybeRecord)
          in Expect.equal
            (get (r.foo << try << r.bar) updatedExample)
            Nothing
      ]
    , describe "making accessors"
      [ let myFoo = makeOneToOne 
                      .foo
                      (\f rec -> {rec | foo = f rec.foo})
        in describe "makeOneToOne" 
          [ test "get" <| \_ ->
              Expect.equal 
                (get (myFoo << r.bar) nestedRecord)
                "Yop"
          , test "set" <| \_ ->
              let updatedRec = (set (r.foo << myFoo) 1 nestedRecord)
              in Expect.equal updatedRec.foo.foo 1
          , test "over" <| \_ -> 
              let updatedRec = (over (myFoo << myFoo) (\n -> n+3) nestedRecord)
              in Expect.equal updatedRec.foo.foo 6
          ]
      , let myOnEach = makeOneToN List.map List.map
        in describe "makeOneToN"
          [ test "get" <| \_ ->
              Expect.equal 
                (get (r.bar << myOnEach << r.foo) recordWithList)
                [3, 5]
          , test "set" <| \_ -> 
              let updatedExample = 
                    (set (r.bar << myOnEach << r.bar) "Greetings" recordWithList)
              in Expect.equal
                (get (r.bar << onEach << r.bar) updatedExample)
                ["Greetings", "Greetings"]
          , test "over" <| \_ -> 
              let updatedExample = 
                    (over (r.bar << myOnEach << r.foo) (\n -> n-2) recordWithList)
              in Expect.equal
                (get (r.bar << onEach << r.foo) updatedExample)
                [1, 3]
          ]
      ]
    ]
