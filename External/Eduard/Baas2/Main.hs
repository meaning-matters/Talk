module Main where

import Data.Map hiding (map)
import Data.Char
import Data.Tuple
import Text.JSON
import ParseLib.Abstract
import Data.List (intersperse)

type Landen = [Land]

data Land = Land Ident TimeZone
	deriving Show
data TimeZone = TZ Float Float
	deriving Show
data Frequency = Freq Ident [Frequentie]
	deriving Show

type Frequentie =  (Freqschema , [(Float,Float)]) --frequentie, aan-uit-schema

data Freqschema = Unifreq Int
		| Multifreq Int Int
		| ListFreq [Freqschema]
	deriving Show

type Landnaam = Map Ident Ident

type Utc = Float
type Dst = Float
type Ident = String
type Naam = String

-- le json

printJson :: Landen -> String
printJson (x:xs) = "{\n" ++ printJson' x ++ Prelude.foldr (\y z -> ",\n" ++ printJson' y ++ z) "" xs ++ "\n}"
		where printJson' (Land a b) = "\t" ++ ['"'] ++ a ++ ['"']++ " : " ++ "\n\t{\n" ++ printJson'' b ++ "\n\t}"
		      printJson'' (TZ a b) = "\t\t" ++ ['"'] ++ "utc" ++ ['"'] ++ " : " ++ show' a ++ ",\n\t\t" ++ ['"'] ++ "dst" ++ ['"']  ++ " : " ++ show' b
show' :: Float -> String
show' x | x > 0 = show x
        | x == 0 = show x --pas hier aan als je niet van UTC houdt, maar wel van type-incorrecte JSON
        | x < 0 = show x

printFreqs :: [Frequency] -> String
printFreqs (x:xs) = "{\n" ++ printFreqs' x ++ Prelude.foldr (\ y z -> ",\n" ++ printFreqs' y ++ z ) "" xs ++ "\n}"
	where printFreqs' (Freq a b) = "\t" ++ ['"'] ++ a ++ ['"'] ++ " : " ++ "\n\t{\n" ++ concat ( prepend "\t\t" (concatFreq $ Prelude.map printFreqs'' b) ) ++ "\n\t}"
	      printFreqs'' :: Frequentie -> [String]
              printFreqs'' (Unifreq a , b) = ["\"frequency1\" : " ++ show a ++ ",\n"] ++  printTijd b -- slechts een frequentie, als je denkt "ik wil alleen frequency1 en frequency2" dan moet je even copypasten wat bij multifreq staat, maar dan even van de show b ook een a maken, dan is het weer goed
	      printFreqs'' (Multifreq a b, c) = ["\"frequency1\" : " ++ show a ++ ",\n"] ++ ["\"frequency2\" : " ++ show b ++ ",\n"] ++  printTijd c --multifreq is bij elkaar opgeteld, dus 2 frequenties
	      printFreqs'' (ListFreq a, b) = if length a == length b
					     then Prelude.foldr (\(i,j) y-> init y ++ [last y ++ ",\n"] ++ printFreqs'' (i,[j])) (printFreqs'' (head a, [head b])) (zip (tail a) (tail b))
					     else if length a > length b --dan alleen de eerste
						  then concatMap (\(i,j) -> printFreqs'' (i,[j])) (zip (take (length b) a) b)
						  else undefined -- dit blijft mogelijk, maar dat land houdt zich dan niet aan enige standaard

printTijd :: [(Float,Float)] -> [String]
printTijd ((x,y):z:xs) = ["\"on\" : " ++ show x ++ ",\n"] ++ ["\"off\" : " ++ show y ++ ",\n"] ++ printTijd (z:xs)
printTijd ((x,y):[]) = ["\"on\" : " ++ show x ++ ",\n"] ++ ["\"off\" : " ++ show y]
printTijd [] = []

concatFreq :: [[String]] -> [String]
concatFreq [a,b,c] = ["\"busy\" : \n","[\n","\t{\n"]  ++ prepend "\t\t" a ++ ["\n\t\t\t}","\n","],\n"] ++["\"congestion\" : \n","[\n","\t{\n"] ++ prepend "\t\t" b ++ ["\n\t\t\t}","\n","],\n"] ++ ["\"ringing\" : \n","[\n","\t{\n"]  ++ prepend "\t\t" c ++ ["\n\t\t\t}","\n","]"]

prependToAll _ [] = []
prependToAll sep (x:xs) = sep : x : prependToAll sep xs

prepend :: String -> [String] -> [String]
prepend sep xs = map concat $ map (prependToAll sep) $ unconcat xs

unconcat = map (\x -> [x])


-- Recognizing functies die de ISO-code ipv de landnaam bij de data zetten

iets = do x <- getLine
	  y <- readFile x
	  let z = parse parseLanden y
	  case z of 
	   [] -> putStr "Nothing"
	   _ -> putStr $ show $ Just $ fst . head $ z


f y = let z = parse parseLanden y
      in  case z of 
	   [] -> Data.Map.empty
	   _ ->  fromList . Prelude.map swap . fst . head $ z

g y = let z = parse parseTijdZones y
      in  case z of 
	   [] -> Nothing
	   _ -> Just $ fst . head $ z

h x y = let a = parse parseLanden x
	    b = parse parseTijdZones y
        in case a of
           [] -> []
	   _ -> case b of
		[] -> []
		_ -> let c = (fromList . Prelude.map swap . fst . head $ a) 
                       in Prelude.map (\(Land d e) -> let land = Data.Map.lookup d c
					              in case land of
							 Nothing -> error ("Land " ++ d ++ " bestaat niet.")
							 (Just eenLand) -> Land eenLand e ) ((fst . head $ b) :: Landen)

k x y = let a = parse parseLanden x
	    b = parse parseFreqs y
	in case a of
	   [] -> []
	   _ -> case b of
		[] -> []
		_ -> let c = (fromList . Prelude.map swap . fst . head $ a)
		     in Prelude.map (\(Freq      d e) -> let land = Data.Map.lookup d c
							 in case land of
							 Nothing -> error ("Land " ++ d ++ " bestaat niet.")
							 (Just eenLand) -> Freq eenLand e ) ((fst . head $ b) :: [Frequency])

m x y = let a = parse parseLanden x
	    b = parse parseFreqs y
	in case a of
	   [] -> Data.Map.empty
	   _ -> case b of
		[] -> Data.Map.empty
		_ -> let c = (fromList . Prelude.map swap . fst . head $ a)
		     in Prelude.foldr (\(Freq      d e) y -> let land = Data.Map.lookup d c
							     in case land of
							     Nothing -> error ("Land " ++ d ++ " bestaat niet.")
							     (Just eenLand) -> Data.Map.insert d eenLand y ) Data.Map.empty ((fst . head $ b) :: [Frequency])

-- functies voor landen

parseLanden = symbol '{' *> greedy parseLand <* spaces <* symbol '}' <* spaces

parseLand :: Parser Char (Ident,Naam)
parseLand = (,) <$ spaces <*> pIdent <* symbol ' ' <* symbol ':' <* symbol ' ' <*> pNaam <* symbol ','
	    <<|> (,) <$ spaces <*> pIdent <* symbol ' ' <* symbol ':' <* symbol ' ' <*> pNaam

pIdent = symbol '"' *> twoAlpha <* symbol '"'
pNaam = symbol '"' *> greedy (satisfy (\x -> isSpace x || isAlpha x || isParens x || x == ',' || x == '.' || x == '-'|| x == '\'')) <* symbol '"'

isParens :: Char -> Bool
isParens x = x == '(' || x == ')'

twoAlpha = (\x y -> [x,y]) <$> satisfy isAlpha <*> satisfy isAlpha

spaces = greedy (satisfy isSpace)
spaces' = greedy (satisfy (== ' '))

-- functies voor tijdzones

parseTijdZones = greedy ( parseTijdZone <* symbol '\r' )
parseTijdZone = (\x y -> Land x y ) <$> greedy notTab <* symbol '\t' <* greedy (greedy notTab <* symbol '\t') <* spaces' <*> pTZ <* spaces'

pTZ = 
    TZ <$> floating' <* symbol '/' <*> floating'
    <<|> TZ 0 <$ token "UTC" <* symbol '/' <*> floating'
    <<|> (\x -> TZ x 0) <$> floating' <* symbol '/' <* token "UTC"
    <<|> (\x -> TZ x x) <$> floating' <* symbol ',' <* spaces' <* floating' --Hier worden landen met meerdere tijdzones genegeerd.
    <<|> (\x -> TZ x x) <$> floating'
    <<|> TZ 0 0 <$ token "UTC"

floating' = floating <<|> symbol '+' *> floating

floating :: Parser Char Float
floating = (\x y -> (fromIntegral x) + (y / 0.6)) <$> integer <*> ( symbol '.' *> pFract `option` 0) 
         <<|> fromIntegral <$> integer

pFract :: Parser Char Float
pFract = Prelude.foldr (\d r -> (fromIntegral ( ord d - ord '0' ) + r) / 10) 0 <$> greedy1 (satisfy isDigit)

notTab = satisfy (\x -> x /= '\t' && x /= '\r' && x/= '\n')

-- functies voor frequenties

parseFreqs = greedy parseFreq <* spaces <* epsilon
parseFreq = (\x y-> Freq x y) <$> greedy notTab <* spaces <*> parsetonen

parsetonen = (\x y z -> [x ,y, z]) <$ token "Busy tone" <*> parseTone <* token "Congestion tone" <*> parseTone <* token "Ringing tone" <*> parseTone
	     <|> (\x@(a , b) z -> [x , (a , Prelude.map (\(i,j) -> (0.5 * i, 0.5 * j)) b) , z]) <$ token "Busy tone" <*> parseTone <* token "Ringing tone" <*> parseTone

parseTone :: Parser Char Frequentie
parseTone = (\x y -> (x,y)) <$ spaces <* symbol '-' <* spaces <*> frequentie <* spaces <*> toonschema <* spaces
	    <|> (\_ -> (Unifreq 0,[])) <$ spaces <* symbol '-' <* spaces <*> token "announcement" <* spaces

frequentie :: Parser Char Freqschema
frequentie =  (\x y -> ListFreq (y:x))<$> greedy1 (frequentie' <* symbol '/') <*> frequentie'
	      <<|>Multifreq <$> natural <* symbol '+' <*> natural <* nietInteressant
	      <<|> Unifreq <$> natural <* symbol 'x' <* natural <* nietInteressant --modulatie
	      <<|> Unifreq <$> natural <* nietInteressant

frequentie' = Multifreq <$> natural <* symbol '+' <*> natural
	      <<|> Unifreq   <$> natural <* symbol 'x' <* natural
	      <<|> Unifreq <$> natural

nietInteressant = greedy ( token "//" <* greedy notTab )

toonschema :: Parser Char [(Float,Float)]
toonschema = (\_ -> [(1000,0)] ) <$> token "continuous" --lege lijst is dus forever & ever
	     <<|> (\x y z-> [(x,y)] ++  concat z) <$> floating <* token " on " <*> floating <* token " off" <*> greedy ( spaces *> toonschema )
	     <<|> (\x y z -> (concat $ replicate x y) ++ z) <$> natural <* symbol 'x' <*> parenthesised toonschema <* spaces <*> toonschema
	     <<|> (\x y -> (concat $ replicate x y) ) <$> natural <* symbol 'x' <* spaces <*> parenthesised toonschema
