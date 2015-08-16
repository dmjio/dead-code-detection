{-# language QuasiQuotes #-}

module RunSpec where

import           Data.String.Interpolate
import           System.Environment
import           System.IO.Silently
import           Test.Hspec

import           Helper
import           Run

spec :: Spec
spec = do
  describe "run" $ do
    it "works" $ do
      let main = ("Main", [i|
            module Main where
            main = used
            used = return ()
            unused = ()
          |])
      withModules [main] $ do
        output <- capture_ $ withArgs ["Main.hs"] run
        output `shouldBe` "Main.hs:4:1: Main.unused\n"

  describe "deadNamesFromFiles" $ do
    it "can be run on multiple modules" $ do
      let a = ("A", [i|
            module A where
            foo = ()
          |])
          b = ("B", [i|
            module B where
            bar = ()
          |])
      withModules [a, b] $ do
        deadNamesFromFiles ["A.hs", "B.hs"] "A.foo"
          `shouldReturn` ["B.hs:2:1: B.bar"]

    it "includes source locations" $ do
      let a = ("A", [i|
            module A where
            foo = ()
          |])
          b = ("B", [i|
            module B where
            bar = ()
          |])
      withModules [a, b] $ do
        deadNamesFromFiles ["A.hs", "B.hs"] "A.foo"
          `shouldReturn` ["B.hs:2:1: B.bar"]
-- fixme: don't show module names?