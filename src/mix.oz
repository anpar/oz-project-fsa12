declare
% Retourne un unique vecteur audio, c'est a dire une liste
% de flottants compris entre -1.0 et 1.0
% <musique> ::= nil | <morceau> '|' <musique>
% <morceau> ::= voix(<voix)) | partition(<partition>)
% | wave(<nom de fichier>) | <filtre> | merge(<musiques avec intensites)
%
% Idee de base : Mix est une fonction recursive (terminale si possible)
% avec un accumulateur

fun {Mix Interprete Music}
   local MixVoice MixAux Fill in
      % =================
      %        FILL
      % =================
      % TODO : il faudra expliquer dans le rapport la subtilite
      % utilisee dans Append pour gagner du temps.
      
      fun {Fill F Duree}
	 local FillAux DesiredLength in
	    DesiredLength = 44100.0*Duree
	    fun {FillAux Length AudioVector}
	       if Length >= DesiredLength then {Reverse AudioVector}
	       else
		  {FillAux Length+1.0 {Append [(0.5*{Sin (2.0*3.1415*F*Length)/44100.0})] AudioVector}}
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
	       case V of nil then {Reverse AudioVector}
	       [] H|T then
		  local F in
		     F = {Pow 2.0 ({IntToFloat H.hauteur}/12.0)} * 440.0
		     {MixVoiceAux T {Append {Fill F H.duree} AudioVector}}
		     % FIX : on aura aussi un probleme de rapidite ici
		     % avec la fonction Append a mon avis, il faudra tester.
		     % Cependant je ne vois pas comment on pourrait regler le probleme ici...
		     % Le mieux qu'on puisse faire c'est placer le plus petit vecteur, c'est
		     % a dire a priori {Fill F H.duree}.
		  end
	       end
	    end
	    {MixVoiceAux V nil}
	 end
      end
	 
      % ================
      %      MIXAUX
      % ================
      fun {MixAux Music AudioVector}
	 case Music of nil then AudioVector
	 [] H|T then
	    case H of voix(V) then
	       {MixAux T {MixVoice V}|AudioVector}
	    [] partition(P) then
	       {MixAux T {Append AudioVector {MixVoice {Interprete P}}}}

	    [] wave(F) then
	       todo
	    [] merge(M) then
	       todo
	    else % Cas des filtres
	       todo
	    end
	 end   
      end
      {MixAux Music nil}
   end
end










declare
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

% TEST ZONE
local
   Tune = [b b c d d c b a g g a b]
   End1 = [etirer(facteur:1.5 b) etirer(facteur:0.5 a) etirer(facteur:2.0 a)]
   End2 = [etirer(facteur:1.5 a) etirer(facteur:0.5 g) etirer(facteur:2.0 g)]
   Interlude = [a a b g a etirer(facteur:0.5 [b c#5])
		b g a etirer(facteur:0.5 [b c#5])
		b a g a etirer(facteur:2.0 d) ]
   Result
   CWD
   Projet
in
   %Result = {Interprete [etirer(facteur:3 a)  a b silence muet([a b c d muet([a b c d])])]}
   Result = {Interprete [Tune End1 Tune End2 Interlude Tune End2]}
   %Result = {Interprete [a a#4 b c c#4 d d#4 e f f#4 g g#4 etirer(facteur:3 [a b e1 silence]) a4 b e2 c#2]}
   %Result = {Interprete [muet([a b]) duree(secondes:9 [a b c silence])]} %
   %Result = {Interprete [muet([a b c]) duree(secondes:4.0 [a b c]) etirer(facteur:3.0 [a b c]) bourdon(note:d [a b c]) transpose(demitons:1 [a b c])]}
   %Result = {Interprete [muet(a) duree(secondes:4.0 a) etirer(facteur:3.0 a) bourdon(note:d a) transpose(demitons:1 a)]}
   %Result ={Interprete [a5 transpose(demitons:1 [muet([a b c]) duree(secondes:4.0 [a b c]) etirer(facteur:3.0 [a b c]) bourdon(note:d [a b c]) transpose(demitons:1 [a b c])])]}
   %{Browse Result}

  % CWD = {Property.condGet 'testcwd' '/Users/Philippe/Desktop/oz-project-fsa12/src/'} %Change ;)

   %Macintosh HD/Users/Philippe ▸ Desktop ▸ oz-project-fsa12

   % For windows
   %[Projet] = {Link ['C:/Users/Philippe/Documents/GitHub/oz-project-fsa12/src/Projet2014_mozart2.ozf']}
   %{Browse {Projet.writeFile 'C:/Users/Philippe/Documents/GitHub/oz-project-fsa12/src/out.wav' {Mix Interprete [partition([a a c c d b]) partition([e e e])]}}}

   % For mac
   [Projet] = {Link ['/Users/Philippe/Desktop/oz-project-fsa12/src/Projet2014_mozart2.ozf']}
   {Browse Projet}
   {Browse Projet.hz}
   {Browse {Projet.writeFile '/Users/Philippe/Desktop/oz-project-fsa12/src/out.wav' {Mix Interprete [partition([a a c c d b]) partition([e e e])]}}}

end

