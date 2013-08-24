module Main where

import Network
import Data.Char
import ParseLib.Abstract
import Network.HTTP
import Network.URI --ghci -package network-2.3.1.0
import System.IO
import Data.Map
import Text.Printf

type Currency = Map String Float
type Land = String

landen = ["USD","CAD","MXN","AUD","NZD","JPY","EUR","CHF","NOK","GBP","DKK","SEK","CNY","SGD","HKD","TWD","RUB","TRY","INR","IDR","ILS","ZAR","SAR","AED"]

main = do let Just uri = parseURI "http://openexchangerates.org/api/latest.json?app_id=03e815602f7341a39f33d0570304a580"
	      req = Request uri GET [] ""
	  res <- simpleHTTP req
	  let Right rsp = res
	      xml = rspBody rsp
	      ((xml',_):_) = parse parseCurr xml
	  x <- readFile "Apples.txt"
	  let apple = fst . head $ parse pApple x
	      aardappel = Prelude.map (zip landen) apple
	      conversionRates = applyConversion xml'
	      potato = Prelude.map (conversion conversionRates) aardappel
	  writeFile "potato.txt" $ strings ++ toonPotato 1 potato ++ stringeind
	  let laagsteLijst = lowestList potato
	      hoogsteLijst = maximumList potato
	  -- putStrLn $ show laagsteLijst
	  -- putStrLn $ show hoogsteLijst
	  -- putStrLn $ (++) "Minimal proceeds: " $ show $ minimum $ zipWith (/) (laagsteLijst)  (tierNormal apple)
	  -- putStrLn $ (++) "Maximal proceeds: " $ show $ maximum $ zipWith (/) (hoogsteLijst)  (tierNormal apple)
	  putStrLn $  minimalProceeds landen (Prelude.map (\x -> zipWith (/) x (tierNormal apple) ) $ transpose $ ( Prelude.map (Prelude.map snd) potato) )

isIets = greedy (satisfy (\x -> x /= '\n')) *> spaces
discarded = spaces *> isIets *> isIets *> isIets *> isIets
spaces = greedy (satisfy isSpace)

-- show functie
strings = "App Store Pricing Matrix\r\n \tU.S. - US$\tCanada - CAD\tMexico - MXN\tAustralia - AUD\tNew Zealand - NZD\tJapan - JPY\tEurope - Euro\tSwitzerland - CHF\tNorway - NOK\tU.K. - GBP\tDenmark - DKK\tSweden - SEK\tChina - CNY\tSingapore - SGD\tHong Kong - HKD\tTaiwan - TWD\tRussia - RUB\tTurkey - TRY\tIndia - INR\tIndonesia - IDR\tIsrael - ILS\tSouth Africa - ZAR\tSaudi Arabia - SAR\tUAE - AED\r\nTier\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\tCustomer Price\tYour Proceeds\r\n"

stringeind = "Note: Price tiers 1b and 2b are for Newsstand In-App Purchases only. Tier 1 and 1b are identical apart from Euro countries (0.99 Euro retail/0.60 Euro proceeds). Tier 2 and 2b are identical apart from Euro-countries (1.99 Euro retail/1.21 Euro proceeds). Proceeds are net of commission."

toonPotato getal (x:xs) = "Tier " ++ show getal ++ " " ++ toonTier x ++ "\n" ++ toonPotato (getal+1) xs
toonPotato _ [] = ""
toonTier x = concatMap showCurr x
showCurr (x,y) = printf "%.2f" x ++ "\t" ++ printf "%.2f" y ++ "\t"

-- haal currencies van het internet en parse deze

parseCurr = fromList <$ token "{" <* discarded <* token "\"rates\": {"  <*> parseRates <* token "}" <* spaces <* token "}"

parseRates :: Parser Char [(String,Float)]
parseRates = greedy parseRate

parseRate :: Parser Char (String,Float)
parseRate = (,) <$ spaces <* symbol '"' <*> greedy (satisfy isAlpha) <* symbol '"'<* symbol ':' <* spaces <*> floating <* symbol ','
            <<|> (,) <$ spaces <* symbol '"' <*> greedy (satisfy isAlpha) <* symbol '"'<* symbol ':' <* spaces <*> floating <* spaces

floating :: Parser Char Float
floating = (\x y -> (fromIntegral x) + y) <$> integer <*> ( symbol '.' *> pFract )
         <<|> fromIntegral <$> integer

pFract :: Parser Char Float
pFract = Prelude.foldr (\d r -> (fromIntegral ( ord d - ord '0' ) + r) / 10) 0 <$> greedy1 (satisfy isDigit)

--parser voor Apples

pApple = isIets *> isIets *> isIets *> pTiers

pTiers :: Parser Char [[(Float,Float)]]
pTiers   = greedy( token "Tier" *> spaces *> integer *> spaces *> pTier )

pTier  = greedy pCurr

pCurr = (,) <$> floating <* spaces <*> floating <* spaces

applyConversion :: Currency -> Currency
applyConversion x = let Just eur = Data.Map.lookup "EUR" x
		        new = Data.Map.map (\y -> (1/y)* eur) x
		    in insert  "EUR" 1 new

conversion :: Currency -> [(String,(Float,Float))] -> [(Float,Float)]
conversion y = Prelude.map (\(naam,(getal1,getal2)) -> let Just waarde = Data.Map.lookup naam y
					                   antw = (waarde * getal1, waarde * getal2)
					               in antw )

lowest = minimum . Prelude.map snd 
-- lowestProceeds = flip smallScale 0 . Prelude.map lowest
lowestList = Prelude.map lowest

maximumList = Prelude.map (maximum . Prelude.map snd)

tierNormal = Prelude.map ( {- (+) 0.01 . -} fst .head)
divTier getal (x:xs) = x / getal : divTier (getal+1) xs
divTier _ [] = []

transpose = Prelude.foldr (zipWith (:)) (repeat [])

minimalProceeds (x:xs) (y:ys) = let (min1,max1) = (minimum y, maximum y)
				    (pos1,pos2) = (succ $ length $ takeWhile (/= min1) y, succ $ length $ takeWhile (/= max1) y )
				in x ++ " min: " ++ show min1 ++"\t Tier:"++ show pos1 ++ "  \t max: " ++ show max1 ++ "  \t tier:"++ show pos2++ "  \t diff:"  ++ show ((max1 - min1) / min1 * 100 )++ "%\n" ++ minimalProceeds xs ys
minimalProceeds [] [] = ""
minimalProceeds _ [] = error "unknown"
minimalProceeds [] _ = error "unknown"   