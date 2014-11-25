declare
fun {Interprete Partition}
   local
      fun {FlattenPartition L}  
	 case L 
	 of nil then nil
	 [] H|T then {Append {FlattenPartition H} {FlattenPartition T}}
	 else [L]
	 end
      end % FlattenPartition

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


      proc {Muet Partition Duree}
	 local FlatPart in
	    FlatPart = {Flatten Partition}
	    Duree = {DureeEchantillon {VoiceConverter FlatPart nil}}
	 end %local
      end %Muet

      fun {Etirer Facteur Part}
	 local Voice EtirerAux in
	    fun {EtirerAux V}
	       case V of nil then nil
	       [] E|T then
		  case E of silence(duree:D) then silence(duree:Facteur*D)|{EtirerAux T}
		  else echantillon(hauteur:E.hauteur
				   duree:(E.duree*Facteur)
				   instrument:E.instrument)|{EtirerAux T}
		  end %case
	       end %case
	    end %EtirerAux
	    Voice = {VoiceConverter {Flatten Part} nil}
	    {EtirerAux Voice}
	     
	 end %local
      end %Etirer
      

      fun {DureeEchantillon ListEchantillon}
	 local DureeEchantillonAux in
	    fun {DureeEchantillonAux List Acc}
	       case List of nil then Acc
	       []H|T then  {DureeEchantillonAux T (Acc+H.duree)}
	       end %case	  
	    end %DureeEchantillonAux
	    {DureeEchantillonAux ListEchantillon 0}
	 end %local
      end %DureeEchantillon
      
      
      fun {VoiceConverter Part Acc}
	 local
	    Hauteur Duree 
	    TheVoice
	 in
	    case Part of nil then Acc
	    []  H|T then
	       case H
	       of muet(P) then
		  TheVoice=silence(duree:Duree)
		  {Muet P Duree}
		  
	       [] duree(secondes:S P) then
		  TheVoice= echantillon(hauteur:Hauteur duree:Duree instrument:none)

	       [] etirer(facteur:F P) then
		  TheVoice ={Etirer F [P]}
	       [] bourdon(note:N P) then skip
	       [] transpose(demitons:DT P) then skip
	       [] silence  then  TheVoice=silence(duree:1)
	       else 
		  TheVoice= echantillon(hauteur:Hauteur duree:1 instrument:none)
		  Hauteur={NumberDemiTons 3}
		     
	       end %case

	       {VoiceConverter T {Append Acc {Flatten [TheVoice]}}}
	    end%case   	    
	 end%local
      end %VoiceConverter

      fun {NumberDemiTons Note}
	 3
      end

      fun {NumberOfNote Partition}
	 local NumberOfNoteAux in
	    fun {NumberOfNoteAux P Acc}
	       case P of nil then Acc
	       []H|T then {NumberOfNoteAux T Acc+1}
	       end
	    end
	    {NumberOfNoteAux Partition 0}
	 end
      end
      
      
      

      FlattenedPartition
      
   in
      FlattenedPartition = {Flatten Partition}
      {VoiceConverter FlattenedPartition nil}
  
      
      
   end % local
end % Interprete



local
   Tune = [b b c d d c b a g g a b]
   End1 = [etirer(facteur:1.5 b) etirer(facteur:0.5 a) etirer(facteur:2.0 a)]
   End2 = [etirer(facteur:1.5 a) etirer(facteur:0.5 g) etirer(facteur:2.0 g)]
   Interlude = [a a b g a etirer(facteur:0.5 [b c#5])
		b g a etirer(facteur:0.5 [b c#5])
		b a g a etirer(facteur:2.0 d) ]
   
   Result
in
   %Result = {Interprete [etirer(facteur:3 a)  a b silence muet([a b c d muet([a b c d])])]}
   %Result = {Interprete [Tune End1 Tune End2 Interlude Tune End2]}
   Result = {Interprete [etirer(facteur:3 [a b silence])]}

   
   {Browse Result}
end


