FasdUAS 1.101.10   ��   ��    k             l     ��  ��    U O set sourceFolder to choose folder with prompt "Select the source image folder"     � 	 	 �   s e t   s o u r c e F o l d e r   t o   c h o o s e   f o l d e r   w i t h   p r o m p t   " S e l e c t   t h e   s o u r c e   i m a g e   f o l d e r "   
  
 l     ��  ��    a [ set targetFolder to (choose folder with prompt "Select the target image folder") as string     �   �   s e t   t a r g e t F o l d e r   t o   ( c h o o s e   f o l d e r   w i t h   p r o m p t   " S e l e c t   t h e   t a r g e t   i m a g e   f o l d e r " )   a s   s t r i n g      l     ��������  ��  ��        l     ����  r         m        �    f d l p  o      ���� 0 parkid parkId��  ��        l     ��������  ��  ��        l    ����  I   ��  
�� .sysodlogaskr        TEXT  m       �     $ E n t e r   t h e   p a r k   I D :  �� !��
�� 
dtxt ! o    ���� 0 parkid parkId��  ��  ��     " # " l    $���� $ r     % & % c     ' ( ' l    )���� ) n     * + * 1    ��
�� 
ttxt + l    ,���� , 1    ��
�� 
rslt��  ��  ��  ��   ( m    ��
�� 
TEXT & l      -���� - o      ���� 0 parkid parkId��  ��  ��  ��   #  . / . l     ��������  ��  ��   /  0 1 0 l   # 2���� 2 r    # 3 4 3 l   ! 5���� 5 c    ! 6 7 6 b     8 9 8 b     : ; : b     < = < l    >���� > I   �� ?��
�� .earsffdralis        afdr ? m    ��
�� afdrcusr��  ��  ��   = m     @ @ � A A X D o c u m e n t s : i P h o n e   P r o j e c t s : I n P a r k : G P S : b i l d e r : ; o    ���� 0 parkid parkId 9 m     B B � C C  : 7 m     ��
�� 
TEXT��  ��   4 o      ���� 0 sourcefolder sourceFolder��  ��   1  D E D l  $ 3 F���� F r   $ 3 G H G l  $ 1 I���� I c   $ 1 J K J b   $ / L M L b   $ - N O N b   $ + P Q P l  $ ) R���� R I  $ )�� S��
�� .earsffdralis        afdr S m   $ %��
�� afdrcusr��  ��  ��   Q m   ) * T T � U U L D o c u m e n t s : i P h o n e   P r o j e c t s : I n P a r k : d a t a : O o   + ,���� 0 parkid parkId M m   - . V V � W W  : K m   / 0��
�� 
TEXT��  ��   H o      ���� 0 targetfolder targetFolder��  ��   E  X Y X l     ��������  ��  ��   Y  Z [ Z l  4� \���� \ O   4� ] ^ ] k   :� _ _  ` a ` Q   : m b c d b r   = O e f e c   = K g h g n   = G i j i 2   C G��
�� 
file j 4   = C�� k
�� 
cfol k o   A B���� 0 sourcefolder sourceFolder h m   G J��
�� 
alst f o      ����  0 filestoconvert filesToConvert c R      ������
�� .ascrerr ****      � ****��  ��   d r   W m l m l c   W i n o n c   W e p q p n   W a r s r 2   ] a��
�� 
file s 4   W ]�� t
�� 
cfol t o   [ \���� 0 sourcefolder sourceFolder q m   a d��
�� 
alis o m   e h��
�� 
list m o      ����  0 filestoconvert filesToConvert a  u v u l  n n��������  ��  ��   v  w�� w O   n� x y x Q   t� z { | z k   w� } }  ~  ~ I  w |������
�� .ascrnoop****      � ****��  ��     ��� � X   }� ��� � � k   �� � �  � � � l  � ��� � ���   � + % my convertImage(aFile, targetFolder)    � � � � J   m y   c o n v e r t I m a g e ( a F i l e ,   t a r g e t F o l d e r ) �  � � � r   � � � � � I  � ��� ���
�� .aevtodocnull  �    alis � o   � ����� 0 thisitem thisItem��   � o      ���� 0 	thisimage 	thisImage �  � � � O   � � � � � k   � � � �  � � � r   � � � � � n   � � � � � 1   � ���
�� 
nmxt � o   � ����� 0 thisitem thisItem � o      ���� 0 ext   �  � � � r   � � � � � n   � � � � � 1   � ���
�� 
pnam � o   � ����� 0 thisitem thisItem � o      ���� 0 n   �  ��� � r   � � � � � b   � � � � � b   � � � � � o   � ����� 0 targetfolder targetFolder � l  � � ����� � n   � � � � � 7 � ��� � �
�� 
ctxt � m   � �����  � l  � � ����� � \   � � � � � l  � � ����� � n   � � � � � 1   � ���
�� 
leng � o   � ����� 0 n  ��  ��   � l  � � ����� � n   � � � � � 1   � ���
�� 
leng � o   � ����� 0 ext  ��  ��  ��  ��   � o   � ����� 0 n  ��  ��   � m   � � � � � � �  j p g � o      ���� 0 newitem newItem��   � m   � � � ��                                                                                  MACS  alis    r  Macintosh HD               �� 2H+   1<�
Finder.app                                                      1��ȹ��        ����  	                CoreServices    ��      ȹi�     1<� 1<Y 1<X  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��   �  � � � s   �  � � � n   � � � � � 1   � ���
�� 
dmns � o   � ����� 0 	thisimage 	thisImage � J       � �  � � � o      ���� 0 w W �  ��� � o      ���� 0 h H��   �  � � � r   � � � I ���� �
�� .sysooffslong    ��� null��   � �� � �
�� 
psof � l  ����� � m   � � � � �    -   l o g o��  ��   � �� ���
�� 
psin � o  ���� 0 n  ��   � o      ���� 0 i   �  � � � Z  < � ���~ � B   � � � o  �}�} 0 i   � m  �|�|   � r  !8 � � � I !4�{�z �
�{ .sysooffslong    ��� null�z   � �y � �
�y 
psof � l %( ��x�w � m  %( � � � � �    -   i c o n _�x  �w   � �v ��u
�v 
psin � o  +.�t�t 0 n  �u   � o      �s�s 0 i  �  �~   �  � � � Z  =� � ��r � � F  =^ � � � F  =R � � � =  =D � � � o  =@�q�q 0 w W � o  @C�p�p 0 h H � ?  GN � � � o  GJ�o�o 0 w W � m  JM�n�n � � B  UZ � � � o  UX�m�m 0 i   � m  XY�l�l   � k  a| � �  � � � I an�k � �
�k .icasscalnull���    obj  � o  ad�j�j 0 	thisimage 	thisImage � �i ��h
�i 
maxi � m  gj�g�g ��h   �  ��f � I o|�e � �
�e .coresavealis       obj  � o  or�d�d 0 	thisimage 	thisImage � �c ��b
�c 
kfil � o  ux�a�a 0 newitem newItem�b  �f  �r   � O  � � � � k  �� � �  � � � Z  �� � ��`�_ � I ���^ ��]
�^ .coredoexbool        obj  � 4  ���\ �
�\ 
file � o  ���[�[ 0 newitem newItem�]   � I ���Z ��Y
�Z .coredeloobj        obj  � 4  ���X �
�X 
file � o  ���W�W 0 newitem newItem�Y  �`  �_   �  ��V � s  ��   4  ���U
�U 
file o  ���T�T 0 thisitem thisItem 4  ���S
�S 
cfol o  ���R�R 0 targetfolder targetFolder�V   � m  ��                                                                                  MACS  alis    r  Macintosh HD               �� 2H+   1<�
Finder.app                                                      1��ȹ��        ����  	                CoreServices    ��      ȹi�     1<� 1<Y 1<X  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��   � �Q I ���P�O
�P .coreclosnull���    obj  o  ���N�N 0 	thisimage 	thisImage�O  �Q  �� 0 thisitem thisItem � o   � ��M�M  0 filestoconvert filesToConvert��   { R      �L�K
�L .ascrerr ****      � **** o      �J�J 0 msg  �K   | I ���I�H
�I .sysodlogaskr        TEXT o  ���G�G 0 msg  �H   y m   n q		�                                                                                  imev  alis    �  Macintosh HD               �� 2H+   1<�Image Events.app                                                2v�Ǚ�Q        ����  	                CoreServices    ��      Ǚ�A     1<� 1<Y 1<X  9Macintosh HD:System:Library:CoreServices:Image Events.app   "  I m a g e   E v e n t s . a p p    M a c i n t o s h   H D  ,System/Library/CoreServices/Image Events.app  / ��  ��   ^ m   4 7

�                                                                                  MACS  alis    r  Macintosh HD               �� 2H+   1<�
Finder.app                                                      1��ȹ��        ����  	                CoreServices    ��      ȹi�     1<� 1<Y 1<X  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��  ��  ��   [  l     �F�E�D�F  �E  �D    l     �C�B�A�C  �B  �A   �@ i      I      �?�>�? 0 convertimage convertImage  o      �=�= 0 thisitem thisItem �< o      �;�; 0 
targetpath 
targetPath�<  �>   O     � Q    � k    �  I   �:�9�8
�: .ascrnoop****      � ****�9  �8    l   �7 !�7      open the image file   ! �"" (   o p e n   t h e   i m a g e   f i l e #$# r    %&% I   �6'�5
�6 .aevtodocnull  �    alis' o    �4�4 0 thisitem thisItem�5  & o      �3�3 0 	thisimage 	thisImage$ ()( O    =*+* k    <,, -.- r    /0/ n    121 1    �2
�2 
nmxt2 o    �1�1 0 thisitem thisItem0 o      �0�0 0 ext  . 343 r    $565 n    "787 1     "�/
�/ 
pnam8 o     �.�. 0 thisitem thisItem6 o      �-�- 0 n  4 9�,9 r   % <:;: b   % :<=< b   % 8>?> o   % &�+�+ 0 
targetpath 
targetPath? l  & 7@�*�)@ n   & 7ABA 7 ' 7�(CD
�( 
ctxtC m   + -�'�' D l  . 6E�&�%E \   . 6FGF l  / 2H�$�#H n   / 2IJI 1   0 2�"
�" 
lengJ o   / 0�!�! 0 n  �$  �#  G l  2 5K� �K n   2 5LML 1   3 5�
� 
lengM o   2 3�� 0 ext  �   �  �&  �%  B o   & '�� 0 n  �*  �)  = m   8 9NN �OO  j p g; o      �� 0 newitem newItem�,  + m    PP�                                                                                  MACS  alis    r  Macintosh HD               �� 2H+   1<�
Finder.app                                                      1��ȹ��        ����  	                CoreServices    ��      ȹi�     1<� 1<Y 1<X  3Macintosh HD:System:Library:CoreServices:Finder.app    
 F i n d e r . a p p    M a c i n t o s h   H D  &System/Library/CoreServices/Finder.app  / ��  ) QRQ s   > RSTS n   > AUVU 1   ? A�
� 
dmnsV o   > ?�� 0 	thisimage 	thisImageT J      WW XYX o      �� 0 w WY Z�Z o      �� 0 h H�  R [\[ r   S ^]^] I  S \��_
� .sysooffslong    ��� null�  _ �`a
� 
psof` l  U Vb��b m   U Vcc �dd    -   l o g o�  �  a �e�
� 
psine o   W X�� 0 n  �  ^ o      �� 0 i  \ fgf Z   _ vhi��h B   _ bjkj o   _ `�
�
 0 i  k m   ` a�	�	  i r   e rlml I  e p��n
� .sysooffslong    ��� null�  n �op
� 
psofo l  g jq��q m   g jrr �ss    -   i c o n _�  �  p �t�
� 
psint o   k l�� 0 n  �  m o      � �  0 i  �  �  g uvu Z   w �wx����w F   w �yzy F   w �{|{ =   w z}~} o   w x���� 0 w W~ o   x y���� 0 h H| ?   } �� o   } ~���� 0 w W� m   ~ ����� �z B   � ���� o   � ����� 0 i  � m   � �����  x I  � �����
�� .icasscalnull���    obj � o   � ����� 0 	thisimage 	thisImage� �����
�� 
maxi� m   � ����� ���  ��  ��  v ��� I  � �����
�� .coresavealis       obj � o   � ����� 0 	thisimage 	thisImage� �����
�� 
kfil� o   � ����� 0 newitem newItem��  � ���� I  � ������
�� .coreclosnull���    obj � o   � ����� 0 	thisimage 	thisImage��  ��   R      �����
�� .ascrerr ****      � ****� o      ���� 0 msg  ��   I  � ������
�� .sysodlogaskr        TEXT� o   � ����� 0 msg  ��   m     ���                                                                                  imev  alis    �  Macintosh HD               �� 2H+   1<�Image Events.app                                                2v�Ǚ�Q        ����  	                CoreServices    ��      Ǚ�A     1<� 1<Y 1<X  9Macintosh HD:System:Library:CoreServices:Image Events.app   "  I m a g e   E v e n t s . a p p    M a c i n t o s h   H D  ,System/Library/CoreServices/Image Events.app  / ��  �@       �������  � ������ 0 convertimage convertImage
�� .aevtoappnull  �   � ****� ������������ 0 convertimage convertImage�� ����� �  ������ 0 thisitem thisItem�� 0 
targetpath 
targetPath��  � 
���������������������� 0 thisitem thisItem�� 0 
targetpath 
targetPath�� 0 	thisimage 	thisImage�� 0 ext  �� 0 n  �� 0 newitem newItem�� 0 w W�� 0 h H�� 0 i  �� 0 msg  � �����P��������N������c������r��������������������
�� .ascrnoop****      � ****
�� .aevtodocnull  �    alis
�� 
nmxt
�� 
pnam
�� 
ctxt
�� 
leng
�� 
dmns
�� 
cobj
�� 
psof
�� 
psin�� 
�� .sysooffslong    ��� null�� �
�� 
bool
�� 
maxi
�� .icasscalnull���    obj 
�� 
kfil
�� .coresavealis       obj 
�� .coreclosnull���    obj �� 0 msg  ��  
�� .sysodlogaskr        TEXT�� �� � �*j O�j E�O� %��,E�O��,E�O��[�\[Zk\Z��,��,2%�%E�UO��,E[�k/EQ�Z[�l/EQ�ZO*����� E�O�j *�a ��� E�Y hO�� 	 �a a &	 	�ja & �a a l Y hO�a �l O�j W X  �j U� �����������
�� .aevtoappnull  �   � ****� k    ���  ��  ��  "��  0��  D��  Z����  ��  ��  � ������ 0 thisitem thisItem�� 0 msg  � < �� �������������� @ B�� T V��
����������������	������������������������ ����������� ��������� ����������������������� 0 parkid parkId
�� 
dtxt
�� .sysodlogaskr        TEXT
�� 
rslt
�� 
ttxt
�� 
TEXT
�� afdrcusr
�� .earsffdralis        afdr�� 0 sourcefolder sourceFolder�� 0 targetfolder targetFolder
�� 
cfol
�� 
file
�� 
alst��  0 filestoconvert filesToConvert��  ��  
�� 
alis
�� 
list
�� .ascrnoop****      � ****
�� 
kocl
�� 
cobj
�� .corecnte****       ****
�� .aevtodocnull  �    alis�� 0 	thisimage 	thisImage
�� 
nmxt�� 0 ext  
�� 
pnam�� 0 n  
�� 
ctxt
�� 
leng�� 0 newitem newItem
�� 
dmns�� 0 w W�� 0 h H
�� 
psof
�� 
psin�� 
�� .sysooffslong    ��� null�� 0 i  �� �
�� 
bool
�� 
maxi
�� .icasscalnull���    obj 
�� 
kfil
�� .coresavealis       obj 
�� .coredoexbool        obj 
�� .coredeloobj        obj 
�� .coreclosnull���    obj �� 0 msg  ����E�O���l O��,�&E�O�j 	�%�%�%�&E�O�j 	�%�%�%�&E�Oa � *a �/a -a &E` W X  *a �/a -a &a &E` Oa [N*j OB_ [a a l kh  �j E` Oa  =�a  ,E` !O�a ",E` #O�_ #[a $\[Zk\Z_ #a %,_ !a %,2%a &%E` 'UO_ a (,E[a k/EQ` )Z[a l/EQ` *ZO*a +a ,a -_ #a . /E` 0O_ 0j *a +a 1a -_ #a . /E` 0Y hO_ )_ * 	 _ )a 2a 3&	 _ 0ja 3&  _ a 4a 2l 5O_ a 6_ 'l 7Y 6a  /*a _ '/j 8 *a _ '/j 9Y hO*a �/*a �/GUO_ j :[OY��W X ; �j UU ascr  ��ޭ