functor 
import
   Open
   Compiler

export 
   readFile: ReadWaveFile
   writeFile: WriteWaveFile
   load: Load
   run: Run
   hz: Hz

define
   %%%%%%%%
   % Misc %
   %%%%%%%%
   
   Hz = 44100
   proc {Assert Cond Exception}
      if {Not Cond} then raise Exception end end
   end
   fun {Run Mix Interprete Music OutF}
      {WriteWaveFile OutF {Mix Interprete Music}}
   end
   fun {Load FileN}
      F = {New Open.file init(name:FileN flags:[read])}
      Contents = {F read(list:$ size:all)}
   in
      {F close}
      {Compiler.evalExpression Contents env _}
   end

   %%%%%%%%%%%%%%%
   % Decode RIFF %
   %%%%%%%%%%%%%%%

   % Recursively parse the structure of the RIFF format

   fun {ParseRiff Reader} Riff in
      Riff = {ParseChunck Reader}
      {Assert {Reader read(1 $)}==nil 'Extraneous bytes at end of file'}
      Riff
   end
   fun {ParseChunck Reader}
      ID = {Reader readAtom(4 $)}
      Size = {Reader readUInt32($)}
   in
      % Ideally, assert that file is long enough, but OS.fseek is broken.
      if ID=='RIFF' orelse ID=='LIST' then
         lck(id:ID size:Size formType:{Reader readAtom(4 $)} data:{ParseChunckList Reader Size-4})
      else
         ck( id:ID size:Size data:{Reader read(Size $)})
      end
   end
   fun {ParseChunckList Reader Size}
      if Size < 0 then raise 'Invalid chunck size found: '#Size end
      elseif Size == 0 then nil
      else Chunck = {ParseChunck Reader} in
         Chunck|{ParseChunckList Reader Size-Chunck.size-8}
      end
   end

   fun {FindChunck Chuncks Name}
      {Filter Chuncks fun {$ Chunck} Chunck.id == Name end}
   end

   % Parse data and fmt chuncks

   fun {ParseFormatChunck Chunck}
      Reader = {New BinaryReader init({New StringReader init(Chunck.data)})}
      Format = format_chunck(
                  format_tag:     {Reader readUInt16($)}
                  channels:       {Reader readUInt16($)}
                  sample_rate:    {Reader readUInt32($)}
                  byte_rate:      {Reader readUInt32($)}
                  block_align:    {Reader readUInt16($)}
                  bits_per_sample:{Reader readUInt16($)}
                  )
   in
      {Assert Format.bits_per_sample==8*(Format.block_align div Format.channels)
       'Bits per sample must be a multiple of 8'}
      Format
   end
   fun {ParseDataChunck Chunck Format}
      Reader = {New BinaryReader init({New StringReader init(Chunck.data)})}
      ReadFunction = case Format.bits_per_sample
                     of 8 then fun {$} ({IntToFloat {Reader readUInt8($)}}-128.0) / 128.0 end
                     [] 16 then fun {$} {IntToFloat {Reader readInt16($)}} / 32768.0 end
                     [] 64 then fun {$} {IntToFloat {Reader readInt24($)}} / 8388608.0 end
                     [] 32 then fun {$} {IntToFloat {Reader readInt32($)}} / 2147483648.0 end
                     else raise 'Bits per samples must be one of 8, 16, 24, 32' end 
                     end
      % Collect N values with ReadFunction
      fun {Collect N}
         if N =< 0 then nil
         else {ReadFunction}|{Collect N-1}
         end
      end
   in
      {Collect Chunck.size div Format.block_align}
   end   

   %%%%%%%%%%%%%%%
   % Encode Riff %
   %%%%%%%%%%%%%%%

   % Encode recursive structure of RIFF format

   fun {EncodeRiff Riff}
      {EncodeChunck Riff}
   end
   fun {EncodeChunck Riff}
      case Riff
      of lck(id:ID formType:Form data:Data) then
         EncodedData = {EncodeChunckList Data}
         Size = {VirtualString.length EncodedData}+4
      in
         ID#{WriteUInt32 Size}#Form#EncodedData
      [] ck(id:ID data:Data) then
         EncodedData = case ID of 'fmt ' then {EncodeFormatData Data} else {EncodeAudioData Data} end
         Size = {VirtualString.length EncodedData}
      in
         ID#{WriteUInt32 Size}#EncodedData
      end
   end
   fun {EncodeChunckList CL}
      case CL of nil then nil
      [] Chunck|T then {EncodeChunck Chunck}#{EncodeChunckList T}
      end
   end

   % Encode data and Fmt chuncks

   fun {EncodeFormatData F}
      {WriteUInt16 F.format_tag}#
      {WriteUInt16 F.channels}#
      {WriteUInt32 F.sample_rate}#
      {WriteUInt32 F.byte_rate}#
      {WriteUInt16 F.block_align}#
      {WriteUInt16 F.bits_per_sample}
   end
   fun {EncodeAudioData Data} Data end


   %%%%%%%%%%%%%%%%%%%%%%
   % Writing BinaryData %
   %%%%%%%%%%%%%%%%%%%%%%

   fun {WriteUInt Bytes I}
      if Bytes =< 0 then nil
      else I mod 256|{WriteUInt Bytes-1 I div 256}
      end
   end
   fun {WriteInt Bytes I} {WriteUInt Bytes if I < 0 then I+{Pow 2 Bytes*8} else I end} end
   fun {WriteUInt16 I} {WriteUInt 2 I} end
   fun {WriteUInt32 I} {WriteUInt 4 I} end
   fun {WriteInt16 I} {WriteInt 2 I} end
   %{WriteInt16 ~337}#{WriteInt16 {Pow 2 16}-337} % == [175 254]

   %%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Stateful Reader classes %
   %%%%%%%%%%%%%%%%%%%%%%%%%%%

   class BinaryReader
      attr
         reader
         endianness
         fold
      meth init(Reader endianness:Endianness <= le)
         reader := Reader
         endianness := Endianness
         fold := case @endianness of le then FoldR [] be then FoldL end
      end
      meth read(Size $)
         % TODO: Check if buffered reading helps.
         {@reader read(list:$ size:Size)}
      end
      meth ReadUInt(Size $)
         fun {EvalAcc Byte Acc} Acc * 256 + Byte end
      in
         {@fold {self read(Size $)} EvalAcc 0}
      end
      meth ReadInt(N $)
         Uint = {self ReadUInt(N $)}
         Half = {Pow 2 N*8-1}
      in
         if Uint >= Half then Uint-Half*2 else Uint end
      end
      meth remainingBytes($) {@reader remainingBytes($)} end
      meth readAtom(Size $) {String.toAtom {self read(Size $)}} end
      meth readUInt8($) {self read(1 $)}.1 end
      meth readUInt32($) {self ReadUInt(4 $)} end
      meth readUInt16($) {self ReadUInt(2 $)} end
      meth readInt16($) {self ReadInt(2 $)} end
      meth readInt24($) {self ReadInt(3 $)} end
      meth readInt32($) {self ReadInt(4 $)} end
   end
   class StringReader
      attr
         current
      meth init(String)
         current := String
      end
      meth read(list:L size:S)
         current := {List.takeDrop @current S L}
      end
   end
   %{{New BinaryReader init({New StringReader init([175 254])})} readInt16($)} % == ~337

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Read and Write operations %
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {ReadWaveFileHelper Name}
      File = {New Open.file init(name:Name flags:[read binary])}
      Reader = {New BinaryReader init(File)}
      Wav = {ParseRiff Reader}
      Format
      Data
   in
      %{Show Wav}
      % Check that RIFF file has WAVE format.
      {Assert Wav.id=='RIFF'          'Not a WAVE file'}
      {Assert Wav.formType=='WAVE'    'Not a WAVE file'}

      % Find and parse the 'fmt ' chunck
      case {FindChunck Wav.data 'fmt '}
      of nil   then {Assert false 'Missing chunck "fmt " in WAVE file'}
      [] _|_|_ then {Assert false 'More than one "fmt " chunck in WAVE file'}
      [] [FormatChunck] then
         {Assert FormatChunck.size==16 'Only PCM encoded music is supported'}
         Format = {ParseFormatChunck FormatChunck}
      end

      % Check that we support the format used
      {Assert Format.channels==1        'More than one audio channel'}
      {Assert Format.format_tag==1      'Only PCM encoded music is supported'}
      {Assert Format.sample_rate==Hz    {VirtualString.toAtom 'Frequency must be '#Hz#'Hz'}}

      % Find and parse the real sound data
      case {FindChunck Wav.data 'data'}
      of nil   then {Assert false 'Missing chunck "data" in WAVE file'}
      [] _|_|_ then {Assert false 'More than one "data" chunck in WAVE file'}
      [] [DataChunck] then
         Data = {ParseDataChunck DataChunck Format}
      end
      
      {File close}
      Data
   end
   proc {WriteWaveFileHelper Name Audio}
      Format = format(
                  format_tag:     1
                  channels:       1
                  sample_rate:    44100
                  bits_per_sample:16
                  block_align:    (Format.bits_per_sample+7) div 8
                  byte_rate:      Format.sample_rate*Format.block_align
                  )
      Data = {Flatten % because WriteInt returns a list
                 {Map Audio 
                     fun {$ Sample}
                         if {Abs Sample} > 1.0 then raise invalidSampleValue(Sample) end end
                         {WriteInt16 {FloatToInt Sample*32767.0}} % 32768.0 may cause overflow.
                     end
                 }
             }
      Riff = lck(id:'RIFF' formType:'WAVE'
                 data:[
                       ck(id:'fmt ' data:Format)
                       ck(id:data data:Data)])
      File = {New Open.file init(name:Name flags:[write binary])}
      EncodedFile = {EncodeRiff Riff}
   in
      {File write(vs:EncodedFile)}
      {File close}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%
   % Exception-safe Wrapers %
   %%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {IsAudioVector A}
      fun {Check V} V >= ~1.0 andthen V =< 1.0 end
   in
      {List.all A Check}
   end

   fun {ReadWaveFile Name}
      try
         {ReadWaveFileHelper Name}
      catch E then
         case E of error(_) then raise E end
         else raise E end
         end
      end
   end
   fun {WriteWaveFile Name Audio}
      try
         if {IsAudioVector Audio} then
            {WriteWaveFileHelper Name Audio}
            ok
         else
            raise 'Le second argument doit etre une liste de valeurs entre -1.0 et 1.0' end
         end
      catch E then
         raise E end
      end
   end
end
