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
      
      fun {VoiceConverter Part Acc}
	 local
	    Haut Duree
	    TheVoice= echantillon(hauteur:Haut duree:Duree instrument:none)
	 in
	    Duree=1
	    case Part of nil then Acc
	    []  H|T then
	       case H of muet(P) then 1
	       [] duree(secondes:S P) then 1
	       [] etirer(facteur:F P) then 1
	       [] bourdon(note:N P) then 1
	       [] transpose(demitons:DT P) then 1
	       else
		  local Z in
		     case H
		     of silence then 1%{VoiceConverter T {Append Acc }}
		     else
			Z = {ToNote H}
			1
		     end
		  end % local
	       end %case
	    end%case
	 end%local
      end %VoiceConverter

      fun {NumberDemiTons Note}
	 Note
      end
      
      

      FlattenedPartition
      
   in
      FlattenedPartition = {FlattenPartition Partition}
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
   Result = {Interprete [Tune End1 Tune End2 Interlude Tune End2]}
   {Browse Result}
end



