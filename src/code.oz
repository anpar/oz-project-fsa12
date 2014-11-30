local Mix Interprete Projet CWD in
   %CWD = {Property.condGet 'testcwd' 'C:/Users/Philippe/Documents/GitHub/oz-project-fsa12/src/'} % Windows Phil
   %CWD = {Property.condGet 'testcwd' '/Users/Philippe/Desktop/oz-project-fsa12/src/'} % Mac Phil
   CWD = {Property.condGet 'testcwd' 'C:/git/oz-project-fsa12/src/'} % Windows Antoine
   [Projet] = {Link [CWD#'Projet2014_mozart2.ozf']}
   % +++++++++++++++++++++++++++++++++++++++++
   % +                MIX                    +
   % +++++++++++++++++++++++++++++++++++++++++
   % Mix prends une musique et doit retourner un vecteur audio.
   % Retourne un unique vecteur audio, c'est a dire une liste
   % de flottants compris entre -1.0 et 1.0
   fun {Mix Interprete Music}
      % =================
      %        FILL
      % =================
      % TODO : il faudra expliquer dans le rapport la subtilite
      % utilisee dans Append pour gagner du temps.
      fun {Fill F Duree}
	 local FillAux DesiredLength in
	    DesiredLength = 44100.0*Duree
	    fun {FillAux Length AudioVector}
	       if Length >= DesiredLength then {Lissage {Reverse AudioVector} DesiredLength}
	       else
		  {FillAux Length+1.0 {Append [{Sin (2.0*3.14159*F*Length)/44100.0}] AudioVector}}
	       end
	    end
	    {FillAux 0.0 nil}
	 end
      end

      % =================
      %     MIXVOICE
      % =================
      fun {MixVoice V}
	 local MixVoiceAux in
	    fun {MixVoiceAux V AudioVector}
	       case V of nil then {Flatten {Reverse AudioVector}}
	       []H|T then
		  local F in 
		     case H of silence(duree:D) then F=0.0
		     else F = {Pow 2.0 ({IntToFloat H.hauteur}/12.0)} * 440.0
		     end
		     {MixVoiceAux T {Append [{Fill F H.duree}] AudioVector}}
		  end
	       end
	    end 
	    {MixVoiceAux V nil}
	 end
      end 
	 
      % ================
      %     MIXMUSIC
      % ================
      fun {MixMusic Music}
	 local MixMusicAux in
	    fun {MixMusicAux Music AudioVector}
	       case Music of nil then {Flatten {Reverse AudioVector}}
	       [] H|T then
		  NewAV
	       in
		  case H of voix(V) then NewAV = {MixVoice V} 
		  [] partition(P) then NewAV = {MixVoice {Interprete P}}
		  [] wave(F) then NewAV = {Projet.readFile F}
		  [] merge(M) then NewAV = {Merge M}
		  [] renverser(M) then NewAV = {Reverse {MixMusic M}}
		  [] repetition(nombre:N M) then NewAV = {RepetitionNB N {MixMusic M}}
		  [] repetition(duree:D M) then NewAV = {RepetitionDuree D {MixMusic M}}
		  [] clip(bas:Bas haut:Haut M) then NewAV = {Clip Bas Haut {MixMusic M}}
		  [] echo(delai:S M) then NewAV = {Merge [0.5#M 0.5#{Flatten [voix([silence(duree:S)]) M]}]}
		  [] echo(delai:S decadence:D M) then
		     local I1 I2 in
			I2 = 1.0/(1.0/D + 1.0)
			I1 = I2/D
			NewAV = {Merge [I1#M I2#{Flatten [voix([silence(duree:S)]) M]}]}
		     end
		  [] echo(delai:S decadence:D repetition:N M) then NewAV = {Merge {Echo S D N M}}
		  [] fondu(ouverture:S1 fermeture:S2 M) then NewAV = {Fondu S1 S2 {MixMusic M}}
		  [] fondu_enchaine(duree:S M1 M2) then NewAV = {FonduEnchaine S {MixMusic M1} {MixMusic M2}}
		  [] couper(debut:S1 fin:S2 M) then  NewAV = {Couper S1 S2 {MixMusic M}}
		  else 
		     NewAV = errormatching
		  end
		  {MixMusicAux T {Append [NewAV] AudioVector}}
	       end   
	    end 
	    {MixMusicAux Music nil}
	 end
      end

      % ==============
      %     FONDU
      % ==============
      fun {Fondu Ouverture Fermeture AV}
	 OuvertureAux = 44100.0*Ouverture
	 FermetureAux = 44100.0*Fermeture
	 Leng = {IntToFloat {Length AV}}
	 fun {FonduAux ActualPlace AV Acc}
	    case AV of nil then {Reverse Acc}
	    [] H|T then
	       if  ActualPlace < OuvertureAux andthen ActualPlace > Leng-FermetureAux then
		  {FonduAux ActualPlace+1.0 T H*(ActualPlace/OuvertureAux)*((Leng-ActualPlace)/(FermetureAux))|Acc}
	       elseif ActualPlace < OuvertureAux then
		  {FonduAux ActualPlace+1.0 T H*(ActualPlace/OuvertureAux)|Acc}
	       elseif ActualPlace > Leng-FermetureAux then 
		  {FonduAux ActualPlace+1.0 T H*((Leng-ActualPlace)/(FermetureAux))|Acc}
	       else {FonduAux ActualPlace+1.0 T H|Acc}
	       end
	    end
	 end
      in
	 {FonduAux 0.0 AV nil}
      end

      % ================
      %  FONDUENCHAINE
      % ================
      fun {FonduEnchaine Duree AV1 AV2}
	 M1={Fondu 0.0 Duree AV1}
	 NBZeros = {Length AV1} - {FloatToInt Duree*44100.0}
	 fun {Music2Generator NB Acc}
	    if NB==0 then Acc
	    else
	       {Music2Generator NB-1 0.0|Acc}
	    end
	 end
	 M2={Music2Generator NBZeros {Fondu Duree 0.0 AV2}} 
      in
	 {Combine M1 M2}
      end

      % ================
      %       ECHO
      % ================
      % INPUT :
      % - S (float) : le delai avant l'echo
      % - D (float) : la décadence de l'echo
      % - N (integer) : le nombre de répétition de l'echo
      % - M (list) : la partition
      % OUTPUT :
      % - (list) Retourne une liste de Intensity#Music que l'on pourra
      % passer en argument a Merge.
      fun {Echo S D N M}
	 local EchoAux IN in
	    IN = 1.0/{Sum N D}
	    fun {EchoAux N I Acc}
	       if N==~1 then Acc
	       elseif N==0 then
		  {EchoAux N-1 I/D {Append [I#M] Acc}}
	       else
		  {EchoAux N-1 I/D {Append [I#{Flatten [voix([silence(duree:S*{IntToFloat N})]) M]}] Acc}}
	       end
	    end
	    {EchoAux N IN nil}
	 end
      end

      % INPUT :
      % - N (entier) : le nombre de repetition
      % - D (float) : la decadence
      % OUTPUT :
      % - (float) La somme des inverses de D^k avec 0 <= k <= N (permet de calculer
      % l'intensite du dernier echo, et donc de trouver toutes les autres)
      fun {Sum N D}
	 local SumAux in
	    fun {SumAux N Acc}
	       if N == ~1 then Acc
	       else
		  {SumAux N-1 Acc+(1.0/{Pow D {IntToFloat N}})}
	       end
	    end
	    {SumAux N 0.0}
	 end
      end
	 
      % ================
      %      MERGE
      % ================
      fun {Merge MusicsWithIntensity}
	 local MergeAux in
	    fun {MergeAux M AudioVector}
	       case M of nil then AudioVector
	       [] H|T then
		  case H of Intensity#NewMusic then
		     NewAudioVector
		  in
		     NewAudioVector = {List.map {MixMusic NewMusic} fun{$ N} Intensity*N end}
		     {MergeAux T {Combine AudioVector NewAudioVector}}
		  end
	       end
	    end 
	    {MergeAux MusicsWithIntensity nil}
	 end
      end 

      % ================
      %     COMBINE
      % ================
      fun {Combine L1 L2}
	 fun {CombineAux L1 L2 Acc}
	    case L1#L2 of nil#nil then {Reverse Acc}
	    [](H1|T1)#(H2|T2) then {CombineAux T1 T2 {Append [H1+H2] Acc}}
	    [] (H|T)#nil then {CombineAux T nil {Append [H] Acc}}
	    [] nil#(H|T) then {CombineAux nil T {Append [H] Acc}}
	    end
	 end 
      in
	 {CombineAux L1 L2 nil}
      end 

      % ==============
      %      CLIP
      % ==============
      fun {Clip Bas Haut OldAudioVector}
	 fun {ClipAux L Acc}
	    case L of nil then {Reverse Acc}
	    [] H|T then
	       if H < Bas then {ClipAux T Bas|Acc}
	       elseif H > Haut then {ClipAux T Haut|Acc}
	       else
		  {ClipAux T H|Acc}
	       end
	    end
	 end
      in
	 {ClipAux OldAudioVector nil}
      end

      % ===============
      %  REPETITIONNB
      % ===============
      fun {RepetitionNB NB AV}
	 fun {RepetitionNBAux NB Acc}
	    if NB==0 then Acc
	    else
	       {RepetitionNBAux NB-1 {Append AV Acc}}
	    end
	 end
      in
	 {RepetitionNBAux NB nil}
      end

      % ===============
      % REPETITIONDUREE
      % ===============
      fun {RepetitionDuree Duree AV}
	 Leng={Length AV}
	 DureeAux={FloatToInt Duree*44100.0}
	 NB=DureeAux div Leng
	 Remaining=DureeAux mod Leng
	 fun {FillEnd Remain AV Acc}
	    if Remain == 0 then {Reverse Acc}
	    else
	       case AV of H|T then
		  {FillEnd Remain-1 T H|Acc}
	       end
	    end	       
	 end
      in
	 {Append {RepetitionNB NB AV} {FillEnd Remaining AV nil}}
      end

      % ===============
      %     COUPER
      % ===============
      fun {Couper Begin End AV}
	 BeginAux=Begin*44100.0
	 EndAux=End*44100.0
	 Leng={IntToFloat {Length AV}}
	 fun {CouperAux AV ActualPlace Acc}
	    case AV of nil then {Reverse Acc}
	    []H|T then
	       if ActualPlace < BeginAux then {CouperAux T ActualPlace+1.0 0.0|Acc}
	       elseif ActualPlace > Leng-EndAux then {CouperAux T ActualPlace+1.0 0.0|Acc}
	       else
		  {CouperAux T ActualPlace+1.0 H|Acc}
	       end
	    end
	 end
      in
	 {CouperAux AV 0.0 nil}
      end

      % ================
      %     LISSAGE
      % ================
      fun {Lissage AV Duree}
	 Attack=0.1*Duree
	 Height1=1.0
	 Decay=0.15*Duree
	 Height2=0.9
	 Sustain=0.85*Duree
	 Release=Duree
	 fun {LissageAux AV ActualPosition Acc}
	    case AV of nil then {Reverse Acc}
	    []H|T then
	       if ActualPosition < Attack then {LissageAux T ActualPosition+1.0 H*(ActualPosition/Attack)|Acc}
	       elseif ActualPosition < Decay then
		  Coef= ((Height2-Height1)*(ActualPosition-Attack)/(Decay-Attack))+Height1
	       in
		  {LissageAux T ActualPosition+1.0 H*Coef|Acc}
	       elseif ActualPosition < Sustain then {LissageAux T ActualPosition+1.0 H*Height2|Acc}
	       else
		  Coef= ((0.0-Height2)*(ActualPosition-Sustain)/(Release-Sustain))+Height2
	       in
		  {LissageAux T ActualPosition+1.0 H*Coef|Acc}
	       end
	    end
	 end	    	     
      in
	 {LissageAux AV 0.0 nil}
      end
   in
      {MixMusic Music} 
   end

   % +++++++++++++++++++++++++++++++++++++++++
   % +            INTERPRETE                 +
   % +++++++++++++++++++++++++++++++++++++++++
   fun {Interprete Partition}
      local
         % ====================
         % INTERPRETEFLATTENED
         % ====================
	 % INPUT : une partition (list) flattened.
	 % OUTPUT : une voix, c'est à dire une liste d'échantillon.
	 fun {InterpreteFlattened FlattenedPartition}
	    local InterpreteFlattenedAux in
	       fun {InterpreteFlattenedAux FlattenedPartition Acc}
		  local
		     Hauteur
		     Duree
		     Echantillon
		  in
		     case FlattenedPartition of nil then Acc
		     []  H|T then
			case H
			of muet(P) then
			   Duree = {VoiceDuration {InterpreteFlattened {Flatten P}}}
			   Echantillon = [silence(duree:Duree)]
			[] duree(secondes:S P) then Echantillon = {DureeTrans S [P]}
			[] etirer(facteur:F P) then Echantillon = {Etirer F [P]}
			[] bourdon(note:N P) then Echantillon = {Bourdon N [P]}
			[] transpose(demitons:DT P) then Echantillon = {Transpose DT [P]}
			[] silence then Echantillon = [silence(duree:1.0)]
			[] instrument(nom:I P) then Echantillon = {Instrument I [P]}
		     else 
			Echantillon = [echantillon(hauteur:Hauteur duree:1.0 instrument:none)]
			Hauteur = {NumberOfSemiTones {ToNote H}}
		     end 
		     {InterpreteFlattenedAux T {Append Acc Echantillon}}
			% FIX : on gagnerait en rapidite en inversant les arguments de Append et en faisant
			% un reverse apres non?
		  end 	    
	       end
	    end 
	    {InterpreteFlattenedAux FlattenedPartition nil}
	 end
      end

	 % ================
	 %    INSTRUMENT
	 % ================
	 % INPUT : une partition (liste) brute et un instrument (atom)
	 % OUTPUT : une voix, c'est a dire une liste d'echantillon dont
	 % l'instrument sera mis a I
      fun {Instrument Instrument Part}
	 local Voice InstrumentAux in
	    % Fonction quand on a pas d'instrument imbrique
	    fun {InstrumentAux V I Acc}
	       case V of nil then Acc
	       [] H|T then
		  case H of silence(duree:D) then {InstrumentAux T I {Append Acc [silence(duree:D)]}}
		  else {InstrumentAux T I {Append Acc [echantillon(hauteur:H.hauteur
								   duree:H.duree
								   instrument:I)]}}
		  end
	       end
	    end
	    Voice = {InterpreteFlattened {Flatten Part}}
	    {InstrumentAux Voice Instrument nil}
	 end
      end
	 
         % ================
         %    DUREETRANS
         % ================
         % INPUT : Une partition (liste) brute et une duree (float)
	 % OUTPUT : Une voix, c'est a dire une liste d'echantillon dont la duree
	 % totale a ete modifie.
      fun {DureeTrans WantedDuration Part}
	 local Voice DureeTransAux TotalDuration in
	    TotalDuration = {VoiceDuration Voice}
	    fun {DureeTransAux V Acc}
	       case V of nil then Acc
	       [] E|T then
		  case E of silence(duree:D) then
		     {DureeTransAux T {Append Acc [silence(duree:(D*(WantedDuration/TotalDuration)))]}}
		  else {DureeTransAux T {Append Acc [echantillon(hauteur:E.hauteur
								 duree:(E.duree*(WantedDuration/TotalDuration))
								 instrument:none)]}}
			% FIX : on gagnerait peut-etre du temps si on inversait les argument du Append
			% et qu'on faisait un reverse au moment de retourner la liste?
		  end	   
	       end
	    end
	    Voice = {InterpreteFlattened {Flatten Part}}
	    {DureeTransAux Voice nil} 	   
	 end
      end

         % ================
         %      ETIRER
         % ================
         % INPUT : une partition (liste) brute et un facteur d'etirement (float)
	 % OUTPUT : une voix, c'est a dire une liste d'echantillon, dont la duree
	 % aura ete multiplie par facteur.
      fun {Etirer Facteur Part}
	 local Voice EtirerAux in
	    fun {EtirerAux V}
	       case V of nil then nil
	       [] E|T then
		  case E of silence(duree:D) then silence(duree:Facteur*D)|{EtirerAux T}
		  else echantillon(hauteur:E.hauteur
				   duree:(E.duree*Facteur)
				   instrument:none)|{EtirerAux T}
		  end 
	       end 
	    end
	    Voice = {InterpreteFlattened {Flatten Part}}
	    {EtirerAux Voice} 
	 end 
      end 

         % ================
         %     BOURDON
         % ================
         % INPUT : une note (pas au format étendu) et une partition (liste) brute
	 % OUTPUT : une voix, c'est à dire une liste d'échantillon, dont toutes les notes
	 % ont été transformé en Note
      fun {Bourdon Note Part}
	 local Voice BourdonAux in
	    fun {BourdonAux V}
	       case Note#V of M#nil then nil
	       [] silence#(E|T) then silence(duree:E.duree)|{BourdonAux T}
	       [] M#(E|T) then
		  echantillon(hauteur:{NumberOfSemiTones {ToNote Note}}
			      duree:E.duree
			      instrument:none)|{BourdonAux T}
	       end 
	    end 
	    Voice = {InterpreteFlattened {Flatten Part}}
	    {BourdonAux Voice} 
	 end 
      end 

         % ================
         %    TRANSPOSE
         % ================
         % INPUT : Un nombre de demi-tons (integer) et une partition (liste) brute
	 % OUTPUT : Une voix, c'est à dire une liste d'échantillon, dont toutes les
	 % notes ont une hauteur transposée de Demitons demi-tons.
      fun {Transpose Demitons Part}
	 local Voice TransposeAux in
	    fun {TransposeAux V}
	       case V of nil then nil
	       [] E|T then
		  case E of silence(duree:D) then silence(duree:D)|{TransposeAux T}
		  else echantillon(hauteur:E.hauteur+Demitons
				   duree:E.duree
				   instrument:none)|{TransposeAux T}
		  end
	       end
	    end
	    Voice = {InterpreteFlattened {Flatten Part}}
	    {TransposeAux Voice} 
	 end
      end

         % ================
         %  VOICEDURATION
         % ================
         % INPUT : une voix, c'est à dire une liste d'échantillon.
	 % OUTPUT : la durée totale de la voix (float).
      fun {VoiceDuration ListEchantillon}
	 local VoiceDurationAux in
	    fun {VoiceDurationAux List Acc}
	       case List of nil then Acc
	       [] H|T then {VoiceDurationAux T (Acc+H.duree)}
	       end 	  
	    end 
	    {VoiceDurationAux ListEchantillon 0.0}
	 end 
      end

         % =================
         % NUMBEROFSEMITONES
         % =================
         % INPUT : une note (au format etendu, il faut donc appliquer ToNote sur l'argument
	 % si necessaire).
	 % OUTPUT : le nombre de demi-tons au dessus (ou en dessous) de a4 (integer)
      fun {NumberOfSemiTones Note}
	 local
	    ReferenceNote = note(nom:a octave:4 alteration:none) 
	    DeltaOctave = Note.octave - ReferenceNote.octave
	    NoteNumber = {NameToNumber Note.nom}
	    ReferenceNoteNumber = {NameToNumber ReferenceNote.nom}
	    DeltaNote = NoteNumber - ReferenceNoteNumber
	    Correction1
	    Correction2
	 in	    
	    if NoteNumber =< 3 then
	       Correction1 = 1
	    else
	       Correction1 = 0
	    end 
	    if Note.alteration == '#' then
	       Correction2 = 1
	    else
	       Correction2 = 0
	    end
	    12*DeltaOctave + 2*DeltaNote + Correction1 + Correction2
	 end
      end

	 % INPUT : un nom de note (atom)
	 % OUTPUT : un chiffre (integer) correspondant, utilise lors
	 % du calcul de demi-tons par rapport a a4
      fun {NameToNumber Name}
	 case Name of c then 1
	 [] d then 2
	 [] e then 3
	 [] f then 4
	 [] g then 5
	 [] a then 6
	 [] b then 7
	 end
      end

         % ================
         %      TONOTE
         % ================
	 % INPUT : une note (au format brute, pas etendu)
	 % OUTPUT : une note au format etendu (record)
      fun {ToNote Note}
	 case Note
	 of Nom#Octave then note(nom:Nom octave:Octave alteration:'#')
	 [] Atom then
	    case {AtomToString Atom}
	    of [N] then note(nom:Atom octave:4 alteration:none)
	    [] [N O] then note(nom:{StringToAtom [N]}
			       octave:{StringToInt [O]}
			       alteration:none)
	    end
	 end
      end
   in
      {InterpreteFlattened {Flatten Partition}}
   end 
end 

   % +++++++++++++++++++++++++++++
   % +        TEST ZONE          +
   % +++++++++++++++++++++++++++++
local 
   Joie = {Projet.load CWD#'joie.dj.oz'}
   Part1 = [etirer(facteur:0.5 [a4 b4 c4 d4 e4 f4])]
   Part2 = [silence c4 d4]
   Part3 = [a muet([a]) duree(secondes:0.77 [a b])]
   Part4 = [duree(secondes:10.0 [a4 b4 c4])]
   Part5 = [a4 b2 e1]
   Part6 = [instrument(nom:guitare [a4 b4 c4])]
   Part7 = [instrument(nom:guitare instrument(nom:piano a4))]
   Part8 = [instrument(nom:guitare [instrument(nom:piano a4) e1])]
   Chat = wave(CWD#'wave/animaux/cat.wav')
   M = partition([a b c])
      
      %Music = [repetition(nombre:3 [partition(Part2)])]
      %Joie = [partition([a b c])]
      %Music = [couper(debut:1.0 fin:1.0 [echo(delai:1.0 decadence:0.75 repetition:10 [partition([a])])])]
      %Music = [fondu(ouverture:2.0 fermeture:2.0 [M])]
      %Music = [partition([a]) partition([b b]) voix([silence(duree:1.0)])]
   Music = Joie
in
      %{Browse begin}
      %{Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
   {Browse {Interprete [Part8]}}
end
end