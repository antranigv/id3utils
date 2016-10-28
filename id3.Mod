MODULE id3;

IMPORT Out := Console, Files;

CONST id3BufLen = 128;
      genresLen = 147;

      offsetID      = 0;
      offsetTitle   = 3;
      offsetArtist  = 33;
      offsetAlbum   = 63;
      offsetYear    = 93;
      offsetComment = 97;

      fieldLength   = 30;

TYPE
  TString* = ARRAY 30 OF CHAR;
  TID*     = ARRAY 4 OF CHAR;
  TYear*   = ARRAY 5 OF CHAR;
  TTitle*  = TString;
  TArtist* = TString;
  TAlbum*  = TString;
  TComment* = TString;

  TID3Tag* = RECORD
    ID*: TID;
    Title*: TString;
    Artist*: TString;
    Album*: TString;
    Year*: TYear;
    Comment: TString;
    Genre*: INTEGER;
  END;

VAR Genres* : ARRAY genresLen OF TString;

PROCEDURE outArray(VAR arr : ARRAY OF CHAR);
VAR
  i : INTEGER;
BEGIN
 i := 0;
 REPEAT
   Out.Int(i, 0); Out.String(": "); Out.Char(arr[i]); Out.Ln;
   INC(i)
 UNTIL i >= LEN(arr);
END outArray;

PROCEDURE dumpArray(VAR arr: ARRAY OF CHAR);
VAR
  F: Files.File;
  R: Files.Rider;
  i: INTEGER;
BEGIN
  F := Files.New("array.dump");
  Files.Set(R, F, 0);
  i := 0;
  REPEAT
    Files.Write(R, arr[i]);
    INC(i);
  UNTIL i = LEN(arr)-1;
  Files.Register(F);
  Files.Close(F);
END dumpArray;

PROCEDURE Extract(VAR src: ARRAY OF CHAR; pos, num: INTEGER; VAR dst: ARRAY OF CHAR);
VAR
  i, j : INTEGER;
BEGIN
  i := pos;
  j := 0;
  REPEAT
    dst[j] := src[i];
	INC(j); INC(i);
  UNTIL (j = LEN(dst) - 1) OR (src[i] = 0X);

  WHILE j < LEN(dst) - 1 DO
    dst[j] := 0X;
	INC(j)
  END
END Extract;

PROCEDURE readID3Tags*(fileName: ARRAY OF CHAR; VAR tag: TID3Tag);
VAR
  F: Files.File;
  R: Files.Rider;
  Buffer: ARRAY id3BufLen OF CHAR;
  len : LONGINT;
BEGIN
  F := Files.Old (fileName);
  IF F # NIL THEN
    len := Files.Length(F);
	Files.Set(R, F, len - id3BufLen);
	Files.ReadBytes(R, Buffer, id3BufLen)
  ELSE
    Out.String("cannot open file '"); Out.String(fileName); Out.Char("'"); Out.Ln;
	HALT(1);
  END;
  (*debugArray(Buffer);*)
  (*dumpArray(Buffer);*)
  Extract(Buffer, offsetID,      3,            tag.ID);                  
  Extract(Buffer, offsetTitle,   fieldLength,  tag.Title);           
  Extract(Buffer, offsetArtist,  fieldLength,  tag.Artist);         
  Extract(Buffer, offsetAlbum,   fieldLength,  tag.Album);           
  Extract(Buffer, offsetYear,    4,            tag.Year);              
  Extract(Buffer, offsetComment, 30,           tag.Comment);       
  tag.Genre := ORD(Buffer[id3BufLen - 1]);
END readID3Tags;                 

PROCEDURE fillZeros(VAR str: ARRAY OF CHAR);
VAR
  i: LONGINT;
BEGIN
  i := LEN(str) -1;
  WHILE str[i] # 0X DO
    str[i] := 0X;
    DEC(i)
  END
END fillZeros;

PROCEDURE writeTagToFile*(VAR fileName: ARRAY OF CHAR; offset: LONGINT; VAR string: ARRAY OF CHAR);
VAR
  F: Files.File;
  R: Files.Rider;
  len, i: LONGINT;
BEGIN
  F := Files.Old (fileName);
  IF F # NIL THEN
    len := Files.Length(F);
	Files.Set(R, F, len - id3BufLen + offset);
	Files.WriteBytes(R, string, LEN(string) - 1)
  ELSE
    Out.String("cannot open file '"); Out.String(fileName); Out.Char("'"); Out.Ln;
	HALT(1);
  END;
  Files.Register(F);
  Files.Close(F)
END writeTagToFile;

PROCEDURE writeIDTagToFile*(fileName: ARRAY OF CHAR; id: TID);
BEGIN
  writeTagToFile(fileName, offsetID, id)
END writeIDTagToFile;

PROCEDURE writeTitleTagToFile*(fileName: ARRAY OF CHAR; title: TTitle);
BEGIN
  writeTagToFile(fileName, offsetTitle, title)
END writeTitleTagToFile;

PROCEDURE writeArtistTagToFile*(fileName: ARRAY OF CHAR; artist: TArtist);
BEGIN
  writeTagToFile(fileName, offsetArtist, artist)
END writeArtistTagToFile;

PROCEDURE writeAlbumTagToFile*(fileName: ARRAY OF CHAR; album: TAlbum);
BEGIN
  writeTagToFile(fileName, offsetAlbum, album)
END writeAlbumTagToFile;

PROCEDURE writeYearTagToFile*(fileName: ARRAY OF CHAR; year: TYear);
BEGIN
  writeTagToFile(fileName, offsetYear, year)
END writeYearTagToFile;

PROCEDURE writeCommentTagToFile*(fileName: ARRAY OF CHAR; comment: TComment);
BEGIN
  writeTagToFile(fileName, offsetComment, comment)
END writeCommentTagToFile;

PROCEDURE writeTag(VAR F: Files.File; VAR R: Files.Rider; offset: INTEGER; string: ARRAY OF CHAR);
VAR
  len: LONGINT;
BEGIN
  len := Files.Length(F);
  Files.Set(R, F, len - id3BufLen + offset);
  Files.WriteBytes(R, string, LEN(string) - 1)
END writeTag;

PROCEDURE writeID3Tags(VAR fileName: ARRAY OF CHAR; tag: TID3Tag);
VAR
  F: Files.File;
  R: Files.Rider;
  len, i: LONGINT;
BEGIN
  fillZeros(tag.Title);
  fillZeros(tag.Artist);
  fillZeros(tag.Album);
  fillZeros(tag.Comment);

  F:= Files.Old(fileName);
  IF F # NIL THEN
    len := Files.Length(F);
	Files.Set(R, F, len - id3BufLen);
    writeTag(F, R, offsetID, tag.ID);
    writeTag(F, R, offsetTitle, tag.Title);
    writeTag(F, R, offsetArtist, tag.Artist);
    writeTag(F, R, offsetAlbum, tag.Album);
    writeTag(F, R, offsetYear, tag.Year);
	writeTag(F, R, offsetComment, tag.Comment);
    Files.WriteInt(R, tag.Genre);
	Files.Register(F);
	Files.Close(F);
  ELSE
    Out.String("cannot open file '"); Out.String(fileName); Out.Char("'"); Out.Ln;
  END;
END writeID3Tags;

PROCEDURE InitGenresArray;
BEGIN
Genres[0] := 'Blues';
Genres[1] := 'Classic Rock';
Genres[2] := 'Country';
Genres[3] := 'Dance';
Genres[4] := 'Disco';
Genres[5] := 'Funk';
Genres[6] := 'Grunge';
Genres[7] := 'Hip- Hop';
Genres[8] := 'Jazz';
Genres[9] := 'Metal';
Genres[10] :=  'New Age';
Genres[11] := 'Oldies';
Genres[12] := 'Other';
Genres[13] := 'Pop';
Genres[14] := 'R&B';
Genres[15] := 'Rap';
Genres[16] := 'Reggae';
Genres[17] := 'Rock';
Genres[18] := 'Techno';
Genres[19] := 'Industrial';
Genres[20] := 'Alternative';
Genres[21] := 'Ska';
Genres[22] := 'Death Metal';
Genres[23] := 'Pranks';
Genres[24] := 'Soundtrack';
Genres[25] := 'Euro-Techno';
Genres[26] := 'Ambient';
Genres[27] := 'Trip-Hop';
Genres[28] := 'Vocal';
Genres[29] := 'Jazz+Funk';
Genres[30] := 'Fusion';
Genres[31] := 'Trance';
Genres[32] := 'Classical';
Genres[33] := 'Instrumental';
Genres[34] := 'Acid';
Genres[35] := 'House';
Genres[36] := 'Game';
Genres[37] := 'Sound Clip';
Genres[38] := 'Gospel';
Genres[39] := 'Noise';
Genres[40] := 'Alternative Rock';
Genres[41] := 'Bass';
Genres[42] := 'Punk';
Genres[43] := 'Space';
Genres[44] := 'Meditative';
Genres[45] := 'Instrumental Pop';
Genres[46] := 'Instrumental Rock';
Genres[47] := 'Ethnic';
Genres[48] := 'Gothic';
Genres[49] := 'Darkwave';
Genres[50] := 'Techno-Industrial';
Genres[51] := 'Electronic';
Genres[52] := 'Pop-Folk';
Genres[53] := 'Eurodance';
Genres[54] := 'Dream';
Genres[55] := 'Southern Rock';
Genres[56] := 'Comedy';
Genres[57] := 'Cult';
Genres[58] := 'Gangsta';
Genres[59] := 'Top 40';
Genres[60] := 'Christian Rap';
Genres[61] := 'Pop/Funk';
Genres[62] := 'Jungle';
Genres[63] := 'Native US';
Genres[64] := 'Cabaret';
Genres[65] := 'New Wave';
Genres[66] := 'Psychadelic';
Genres[67] := 'Rave';
Genres[68] := 'Showtunes';
Genres[69] := 'Trailer';
Genres[70] := 'Lo-Fi';
Genres[71] := 'Tribal';
Genres[72] := 'Acid Punk';
Genres[73] := 'Acid Jazz';
Genres[74] := 'Polka';
Genres[75] := 'Retro';
Genres[76] := 'Musical';
Genres[77] := 'Rock & Roll';
Genres[78] := 'Hard Rock';
Genres[79] := 'Folk';
Genres[80] := 'Folk-Rock';
Genres[81] := 'National Folk';
Genres[82] := 'Swing';
Genres[83] := 'Fast Fusion';
Genres[84] := 'Bebob';
Genres[85] := 'Latin';
Genres[86] := 'Revival';
Genres[87] := 'Celtic';
Genres[88] := 'Bluegrass';
Genres[89] := 'Avantgarde';
Genres[90] := 'Gothic Rock';
Genres[91] := 'Progressive Rock';
Genres[92] := 'Psychedelic Rock';
Genres[93]:= 'Symphonic Rock';
Genres[94] := 'Slow Rock';
Genres[95] := 'Big Band';
Genres[96] := 'Chorus';
Genres[97] := 'Easy Listening';
Genres[98] := 'Acoustic';
Genres[99] := 'Humour';
Genres[100] := 'Speech';
Genres[101] := 'Chanson';
Genres[102] := 'Opera';
Genres[103] := 'Chamber Music';
Genres[104] := 'Sonata';
Genres[105] := 'Symphony';
Genres[106] := 'Booty Bass';
Genres[107] := 'Primus';
Genres[108] := 'Porn Groove';
Genres[109] := 'Satire';
Genres[110] := 'Slow Jam';
Genres[111] := 'Club';
Genres[112] := 'Tango';
Genres[113] := 'Samba';
Genres[114] := 'Folklore';
Genres[115] := 'Ballad';
Genres[116] := 'Power Ballad';
Genres[117] := 'Rhytmic Soul';
Genres[118] := 'Freestyle';
Genres[119] := 'Duet';
Genres[120] := 'Punk Rock';
Genres[121] := 'Drum Solo';
Genres[122] := 'Acapella';
Genres[123] := 'Euro-House';
Genres[124] := 'Dance Hall';
Genres[125] := 'Goa';
Genres[126] := 'Drum & Bass';
Genres[127] := 'Club-House';
Genres[128] := 'Hardcore';
Genres[129] := 'Terror';
Genres[130] := 'Indie';
Genres[131] := 'BritPop';
Genres[132] := 'Negerpunk';
Genres[133] := 'Polsk Punk';
Genres[134] := 'Beat';
Genres[135] := 'Christian Gangsta';
Genres[136] := 'Heavy Metal';
Genres[137] := 'Black Metal';
Genres[138] := 'Crossover';
Genres[139] := 'Contemporary C';
Genres[140] := 'Christian Rock';
Genres[141] := 'Merengue';
Genres[142] := 'Salsa';
Genres[143] := 'Thrash Metal';
Genres[144] := 'Anime';
Genres[145] := 'JPop';
Genres[146] := 'SynthPop';


END InitGenresArray;

BEGIN
InitGenresArray;

END id3.

