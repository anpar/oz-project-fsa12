% Vous ne pouvez pas utiliser le mot-cle 'declare'.
local Mix Interprete Projet CWD in
   % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
   % modifiez sa valeur pour correspondre a votre systeme.

   % CWD = {Property.condGet 'testcwd' 'C:/Users/Philippe/Documents/GitHub/oz-project-fsa12/src/'} % Windows Phil
   % CWD = {Property.condGet 'testcwd' '/Users/Philippe/Desktop/oz-project-fsa12/src/'} % Mac Phil
   CWD = {Property.condGet 'testcwd' 'C:/git/oz-project-fsa12/src/'} % Windows Antoine
   
   % Si vous utilisez Mozart 1.4, remplacez la ligne précédente par celle-ci :
   % [Projet] = {Link ['Projet2014_mozart1.4.ozf']}
   %
   % Projet fournit quatre fonctions :
   % {Projet.run Interprete Mix Music 'out.wav'} = ok OR error(...) 
   % {Projet.readFile FileName} = AudioVector OR error(...)
   % {Projet.writeFile FileName AudioVector} = ok OR error(...)
   % {Projet.load 'music_file.dj.oz'} = La valeur oz contenue dans le fichier chargé (normalement une <musique>).
   %
   % et une constante :
   % Projet.hz = 44100, la fréquence d'échantilonnage (nombre de données par seconde)
   [Projet] = {Link [CWD#'Projet2014_mozart2.ozf']}

   local
      Audio = {Projet.readFile CWD#'wave/animaux/cow.wav'}
   in
      % +++++++++++++++++++++++++++++++++++++++++
      % +                MIX                    +
      % +++++++++++++++++++++++++++++++++++++++++
      
      % Mix prends une musique et doit retourner un vecteur audio.
      % Retourne un unique vecteur audio, c'est a dire une liste
      % de flottants compris entre -1.0 et 1.0
      % <musique> ::= nil | <morceau> '|' <musique>
      % <morceau> ::= voix(<voix)) | partition(<partition>)
      % | wave(<nom de fichier>) | <filtre> | merge(<musiques avec intensites)
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
		  if Length >= DesiredLength then {Reverse AudioVector} % est-ce vraiment necessaire de faire un reverse pour une note?
		  else
		     {FillAux Length+1.0 {Append [(0.5*{Sin (2.0*3.14159*F*Length)/44100.0})] AudioVector}}
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
         %      MIXMUSIC
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
		     [] couper(debut:S1 fin:S2 M) then  NewAV = nil
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
		  if  ActualPlace < OuvertureAux andthen ActualPlace > Leng-FermetureAux
		     {FonduAux ActualPlace+1.0 T H*(ActualPlace/OuvertureAux)*((Leng-ActualPlace)/(FermetureAux))|Acc}
		  elseif ActualPlace < OuvertureAux then
		     {FonduAux ActualPlace+1.0 T H*(ActualPlace/OuvertureAux)|Acc}
		  elseif ActualPlace > Leng-FermetureAux then 
		     {FonduAux ActualPlace+1.0 T H*((Leng-ActualPlace)/(FermetureAux))|Acc}
		  else  {FonduAux ActualPlace+1.0 T H|Acc}
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
	 % - D (float) : la d�cadence de l'echo
	 % - N (integer) : le nombre de r�p�tition de l'echo
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
		     % IntToFloat obligatoire cette fois puisque le nombre de
		     % repetition est un entier
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
		     % IntToFloat obligatoire cette fois puisque le nombre de
		     % repetition est un entier
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

	 % FIN DES DEFINITIONS DE FONCTIONS AUXILIAIRES
      in
	 {MixMusic Music} 
      end

      % +++++++++++++++++++++++++++++++++++++++++
      % +            INTERPRETE                 +
      % +++++++++++++++++++++++++++++++++++++++++
      % Interprete doit interpreter une partition
      fun {Interprete Partition}
         % Local to declare all the auxiliary function
	 local
            % ================
            %  VOICECONVERTER
            % ================
            % Convert a partition to a voice, which is a list of sample
	    fun {VoiceConverter Part}
	       local VoiceConverterAux in
		  fun {VoiceConverterAux Part Acc}
		     local
			Hauteur Duree 
			Sample % list of sample
		     in
			case Part of nil then Acc
			[]  H|T then
			   case H
			   of muet(P) then
			      Sample=[silence(duree:Duree)]
			      {Muet [P] Duree}
			   [] duree(secondes:S P) then Sample={DureeTrans S [P]}
			   [] etirer(facteur:F P) then Sample={Etirer F [P]}
			   [] bourdon(note:N P) then Sample={Bourdon N [P]}
			   [] transpose(demitons:DT P) then Sample={Transpose DT [P]}
			   [] silence  then Sample=[silence(duree:1.0)]
			   else 
			      Sample=[echantillon(hauteur:Hauteur duree:1.0 instrument:none)]
			      Hauteur={NumberOfSemiTones {ToNote H}}
			   end 
			   {VoiceConverterAux T {Append Acc Sample}} 
			end 	    
		     end
		  end 
		  {VoiceConverterAux Part nil}
	       end
	    end 

            % ================
            %       MUET
            % ================
            % Transform a partition with the muet transformation
	    proc {Muet Partition Duree}
	       local FlatPart in  
		  FlatPart = {Flatten Partition}
		  Duree = {VoiceDuration {VoiceConverter FlatPart}}
	       end
	    end

            % ================
            %    DUREETRANS
            % ================
            % Transform a partition with the duree transformation
	    fun {DureeTrans WantedDuration Part}
	       local Voice DureeAux TotalDuration in
		  Voice = {VoiceConverter {Flatten Part}}
		  TotalDuration = {VoiceDuration Voice}
		  fun {DureeAux V}
		     case V of nil then nil
		     [] E|T then
			case E of silence(duree:D)
			then silence(duree:(D*(WantedDuration/TotalDuration)))|{DureeAux T}
			else echantillon(hauteur:E.hauteur
					 duree:(E.duree*(WantedDuration/TotalDuration))
					 instrument:none)|{DureeAux T}
			end
		     end
		  end 
		  {DureeAux Voice} 	   
	       end
	    end

            % ================
            %      ETIRER
            % ================
            % Transform a partition with the etirer transformation
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
		  Voice = {VoiceConverter {Flatten Part}}
		  {EtirerAux Voice} 
	       end 
	    end 

            % ================
            %     BOURDON
            % ================
            % Transform a partition with the bourdon transformation
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
		  Voice = {VoiceConverter {Flatten Part}}
		  {BourdonAux Voice} 
	       end 
	    end 

            % ================
            %    TRANSPOSE
            % ================
            % Transform a partition with the transpose transformation
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
		  Voice = {VoiceConverter {Flatten Part}}
		  {TransposeAux Voice} 
	       end
	    end

            % ================
            %  VOICEDURATION
            % ================
            % Compute the duration of a voice
	    fun {VoiceDuration ListEchantillon}
	       local VoiceDurationAux in
		  fun {VoiceDurationAux List Acc}
		     case List of nil then Acc
		     []H|T then  {VoiceDurationAux T (Acc+H.duree)}
		     end 	  
		  end 
		  {VoiceDurationAux ListEchantillon 0.0}
	       end 
	    end

            % =================
            % NUMBEROFSEMITONES
            % =================
            % Compute the number of semitones above or below note a4. The argument note is already in the extended format.
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

            % ================
            %  NAMETONUMBER
            % ================
            % Transform the name of a note to a number
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
            % Transform a note in the extended format
            % Nom | Nom#Octave | NomOctave -> note(nom:Nom octave:Octave alteration:'#'|none)
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
      
	    FlattenedPartition
	 in
	    FlattenedPartition = {Flatten Partition}
	    {VoiceConverter FlattenedPartition}
	 end 
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
      Chat = wave(CWD#'wave/animaux/cat.wav')

      M = partition([a b c])
      %Music = [repetition(nombre:3 [partition(Part2)])]
      %Joie = [partition([a b c])]
      Music = [echo(delai:1.0 decadence:0.75 repetition:10 [partition([a])])]
      %Music = [fondu(ouverture:2.0 fermeture:2.0 [M])]
      %Music = [partition([a]) partition([b b]) voix([silence(duree:1.0)])]
   in
      % Votre code DOIT appeler Projet.run UNE SEULE fois. Lors de cet appel,
      % vous devez mixer une musique qui demontre les fonctionalites de votre
      % programme.
      %
      % Si votre code devait ne pas passer nos tests, cet exemple serait le
      % seul qui ateste de la validite de votre implementation.
      {Browse begin}
      {Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
   end
end



