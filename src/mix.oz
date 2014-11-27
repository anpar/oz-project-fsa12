declare
% Retourne un unique vecteur audio, c'est à dire une liste
% de flottans compris entre -1.0 et 1.0
% <musique> ::= nil | <morceau> '|' <musique>
% <morceau> ::= voix(<voix)) | partition(<partition>)
% | wave(<nom de fichier>) | <filtre> | merge(<musiques avec intensités)
%
% Idée de base : Mix est une fonction récursive (terminale si possible)
% avec un accumulateur

fun {Mix Interprete Music}
   local MixVoice MixAux Fill in
      % =================
      %        FILL
      % =================
      % TODO : il faudra expliquer dans le rapport la subtilité
      % utilisée dans Append pour gagner du temps.
      fun {Fill F Duree}
	 local FillAux DesiredLength in
	    DesiredLength = 44100.0*Duree
	    fun {FillAux Length AudioVector}
	       if Length >= DesiredLength then
		  {Reverse AudioVector}
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
	       case V of nil then AudioVector
	       [] H|T then
		  local F in
		     F = {Pow 2.0 ({IntToFloat H.hauteur}/12.0)} * 440.0
		     {MixVoiceAux T {Append {Fill F H.duree} AudioVector}}
		     % FIX : on aura aussi un problème de rapidité ici
		     % avec la fonction Append à mon avis, il faudra tester.
		     % Cependant je ne vois pas comment on pourrait règler le problème ici...
		     % Le mieux qu'on puisse faire c'est placer le plus petit vecteur, c'est
		     % à dire a priori {Fill F H.duree}.
		  end
	       end
	    end
	    {MixVoiceAux V nil}
	 end
      end
	 
      % ================
      %      MIXAUX
      % ================
      fun {MixAux Interprete Music AudioVector}
	 case Music of nil then AudioVector
	 [] H|T then
	    case H of voix(V) then
	       {MixAux Interprete T {Append AudioVector {MixVoice V}}}
	    [] partition(P) then
	       {MixAux Interprete T {Append AudioVector {Mix Interprete voix({Interprete P})}}}
	    [] wave(F) then
	       todo
	    [] merge(M) then
	       todo
	    else % Cas des filtres
	       todo
	    end
	 end   
      end
      {MixAux Interprete Music nil}
   end
end
     

