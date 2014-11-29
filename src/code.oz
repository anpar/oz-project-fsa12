% Vous ne pouvez pas utiliser le mot-clé 'declare'.
local Mix Interprete Projet CWD in
   % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
   % modifiez sa valeur pour correspondre à votre système.

   %CWD = {Property.condGet 'testcwd' 'C:/Users/Philippe/Documents/GitHub/oz-project-fsa12/src/'} % Windows Phil
   CWD = {Property.condGet 'testcwd' '/Users/Philippe/Desktop/oz-project-fsa12/src/'} %Mac Phil

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
      % Mix prends une musique et doit retourner un vecteur audio.
      % Retourne un unique vecteur audio, c'est a dire une liste
      % de flottants compris entre -1.0 et 1.0
      % <musique> ::= nil | <morceau> '|' <musique>
      % <morceau> ::= voix(<voix)) | partition(<partition>)
      % | wave(<nom de fichier>) | <filtre> | merge(<musiques avec intensites)
      %
      % Idee de base : Mix est une fonction recursive (terminale si possible)
      % avec un accumulateur
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
		  if Length >= DesiredLength then {Reverse AudioVector} % est-ce vraiment nécessaire de faire un reverse pour une note?
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
        		   % FIX : on aura aussi un probleme de rapidite ici
		           % avec la fonction Append a mon avis, il faudra tester.
		           % Cependant je ne vois pas comment on pourrait regler le probleme ici...
		           % Le mieux qu'on puisse faire c'est placer le plus petit vecteur, c'est
		           % a dire a priori {Fill F H.duree}.
		     end
		  end
	       end %MixVoiceAux
	       {MixVoiceAux V nil}
	    end
	 end %MixVoice
	 
            % ================
            %      MIXMUSIC
            % ================
	 fun {MixMusic Music}
	    local MixMusicAux in
	       fun {MixMusicAux Music AudioVector}
		  case Music of nil then {Flatten {Reverse AudioVector}}
		  [] H|T then
		     case H of voix(V) then {MixMusicAux T {Append AudioVector [{MixVoice V}]}}
		     [] partition(P) then {MixMusicAux T {Append AudioVector [{MixVoice {Interprete P}}]}}
		     [] wave(F) then {MixMusicAux T {Append AudioVector [{Projet.readFile F}]}}
		     [] merge(M) then {MixMusicAux T {Append AudioVector [{Merge M}]}}
		     [] renverser(M) then todo
		     [] repetition(nombre:N M) then todo
		     [] repetition(duree:D M) then todo
		     [] clip(bas:Bas haut:Haut M) then todo
		     [] echo(delai:S M) then todo
		     [] echo(delai:S decadence:F M) then todo
		     [] echo(delai:S decadence:F repetition:N M) then todo
		     [] fondu(ouverture:S1 fermeture:S2 M) then todo
		     [] fondu_enchaine(duree:S M1 M2) then todo
		     [] couper(debut:S1 fin:S2 M) then todo
		     else 
			errormatching
		     end
		  end   
	       end %MixMusicAux
	       {MixMusicAux Music nil}
	    end
	 end %MixMusic
	    
	 
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
	       end %MergeAux
	       {MergeAux MusicsWithIntensity nil}
	    end
	 end %Merge

	    % ================
            %      COMBINE
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
	 end % Combine

      in
	 {MixMusic Music}
	 
      end %Mix
	 


      % Interprete doit interpréter une partition
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
			Sample %list of sample
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

   local 
      Joie = {Projet.load CWD#'joie.dj.oz'}
      Music = [merge([0.2#Joie 0.8#[wave(CWD#'wave/animaux/cat.wav')]])]
   in
      % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
      % vous devez mixer une musique qui démontre les fonctionalités de votre
      % programme.
      %
      % Si votre code devait ne pas passer nos tests, cet exemple serait le
      % seul qui ateste de la validité de votre implémentation.
      {Browse begin}
      {Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
   end
end
