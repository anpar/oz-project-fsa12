% Vous ne pouvez pas utiliser le mot-clé 'declare'.
local Mix Interprete Projet CWD in
   % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
   % modifiez sa valeur pour correspondre à votre système.
   CWD = {Property.condGet 'testcwd' '/home/layus/ucl/fsab1402/2014-2015/projet_2014/src/'}

   % Si vous utilisez Mozart 1.4, remplacez la ligne précédente par celle-ci :
   % [Projet] = {Link ['Projet2014_mozart1.4.ozf']}
   %
   % Projet fournit quatre fonctions :
   % {Projet.run Interprete Mix Music 'out.wav'} = ok OR error(...) 
   % {Projet.readFile FileName} = audioVector(AudioVector) OR error(...)
   % {Projet.writeFile FileName AudioVector} = ok OR error(...)
   % {Projet.load 'music_file.oz'} = Oz structure.
   %
   % et une constante :
   % Projet.hz = 44100, la fréquence d'échantilonnage (nombre de données par seconde)
   [Projet] = {Link [CWD#'Projet2014_mozart2.ozf']}

   local
      Audio = {Projet.readFile CWD#'wave/animaux/cow.wav'}
   in
      % Mix prends une musique et doit retourner un vecteur audio.
      fun {Mix Interprete Music}
	 Audio
      end

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
			      Sample=silence(duree:Duree)
			      {Muet [P] Duree}
			   [] duree(secondes:S P) then Sample={DureeTrans S [P]}
			   [] etirer(facteur:F P) then Sample={Etirer F [P]}
			   [] bourdon(note:N P) then Sample={Bourdon N [P]}
			   [] transpose(demitons:DT P) then Sample={Transpose DT [P]}
			   [] silence  then Sample=silence(duree:1.0)
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
      Music = {Projet.load CWD#'joie.dj.oz'}
   in
      % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
      % vous devez mixer une musique qui démontre les fonctionalités de votre
      % programme.
      %
      % Si votre code devait ne pas passer nos tests, cet exemple serait le
      % seul qui ateste de la validité de votre implémentation.
      {Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
   end
end
