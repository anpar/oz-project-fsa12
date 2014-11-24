declare
fun {Interprete Partition}
   local
      fun {FlattenPartition L}
	 local
	    fun{Append Xs Ys}
	       case Xs
	       of nil then Ys
	       [] H|T then H|{Append T Ys} 
	       end
	    end
	    
	 in 
	    
	    case L 
	    of nil then nil
	    [] H|T then {Append {FlattenPartition H} {FlattenSuiteDePartition T}}
	    else [L]
	    end
	 end % local
      end % FlattenPartition

      fun {FlattenSuiteDePartition L}
	 local
	    fun{Append Xs Ys}
	       case Xs
	       of nil then Ys
	       [] H|T then H|{Append T Ys} 
	       end
	    end
	    
	 in 
	    
	    case L 
	    of nil then nil
	    [] H|T then {Append {FlattenPartition H} {FlattenSuiteDePartition T}}
	    else [L]
	    end
	 end % local
      end % FlattenSuiteDePartition

      FlattenedPartition
      
   in
      FlattenedPartition = {FlattenPartition Partition}
      FlattenedPartition

% ton code ici
 
      
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


   