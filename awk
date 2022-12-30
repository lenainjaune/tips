RO en attente de la fin de migration









































# quote et dquote
```awk
awk '
BEGIN {
	QUOTE = "\x27"
	print QUOTE "simple quote" QUOTE " \"double quote\""
}'
```

# Multiline string
Dans un script bash
```sh
awk '
BEGIN {
print "cou\
cou" 
}'
```
Remarque : on peut couper les chaines


# awk coloured like grep (needs gawk for gensub)
Dans une chaine, il faut ajouter \033[XXm (couleur à afficher) et de finir avec \033[0m
Les autres codes : https://misc.flogisoft.com/bash/tip_colors_and_formatting
```sh
# Exemple pratique : la commande "ip ad" avec les IPs en couleur verte
ip ad | awk '/^[0-9]+:/ ; /inet6?/ { print '\
'gensub( /^(.+inet6? )([a-f0-9.:/]+)(.+)$/ , "\\1\033[032m\\2\033[0m\\3" , "g" ) }'
```
<pre>
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    inet <span style="color:green">127.0.0.1/8</span> scope host lo
    inet6 <span style="color:green">::1/128</span> scope host 
2: ens3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    inet <span style="color:green">192.168.0.15/24</span> brd 192.168.0.255 scope global dynamic ens3
    inet6 <span style="color:green">2a01:e0a:4dd:4eb0:5054:ff:feab:eee3/64</span> scope global dynamic mngtmpaddr 
    inet6 <span style="color:green">fe80::5054:ff:feab:eee3/64</span> scope link 
</pre>

nota : la couleur est préservée dans les pipes (ici sort ne supprime pas la couleur)
```sh
user@host:~# df -h | awk '{ print gensub( /[[:space:]]([0-9,]+)([KMGT%]*)/ , "\033[032m\\1\033[0m\\2" , "g" ) }' |sort
```


# Utiliser une variable système dans awk
nota : on NE doit pas mettre d'espaces entre les quotes => '$x' est BON , ' $x ' est MAUVAIS
```sh
# Ici la variable externe $PATH
user@host:~# awk 'BEGIN { print "PATH='$PATH'" }'
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

# Modifier variable externe
Le but est de communiquer des valeurs entre le shell (variables externes) et les variables awk

## Création la variable $newvar depuis awk vers le shell
nota : AUCUN espaces autour du égal dans la chaine print => "a=1" est BON , "a = 1" est MAUVAIS
```sh
user@host:~# echo "newvar=$newvar" ; r=$( awk 'BEGIN { print "newvar=1" }' ) ; eval $r ; echo "newvar=$newvar"
newvar=
newvar=1
```

## Modification de la variable $a avec awk
```sh
// a=1 au début
// dans awk on affiche : "a=" '$a' + 1 
//	=> on expand $a : "a=" '1' + 1
//	=> concaténation chaines quote '...'xxx'...' = '...xxx...' : "a=" 1 + 1 (voir dessus la remarque sur les espaces entre quotes)
//	=> concaténation awk : "a=2" (voir dessus la remarque sur les espaces autour du égal)
// $r contiendra donc "a=2"
// il ne reste qu'à évaluer $r ...
// ... pour constater que la modification a fonctionné
user@host:~# a=1 ; r=$( awk 'BEGIN { print "a=" '$a' + 1 }' ) ; eval $r ; echo "a=$a"
a=2
```

# Run external command and get result
```sh
// resultat sur une ligne
user@host:~# awk 'BEGIN { "whoami" | getline result ; print result }' 

// resultat sur plusieurs lignes
user@host:~# awk 'BEGIN { while ( "ls -l" | getline result ) print result }'
```


# Associative array

## Ne garder que la première ocurrence

```sh
user@host:~# echo -e "a\nb\na" | awk '{ if ( ! ( $0 in a ) ) a[ $0 ] = $0 } END { for ( i in a ) { print a[ i ] } }'
a
b
```

# Reverse regex

```sh
user@host:~# ps aux | grep 'bash.*hdd' | awk '!/grep/ {print $2}' 
```

# Ignorer la casse

```sh
user@host:~# echo -e "a.jpg\nb.JPG" |awk 'BEGIN { IGNORECASE = 1 } /\.jpg/'
```

# Séparateur autre chose que saut de ligne

Soit les lignes suivantes :
```sh
user@host:~# echo -e "-a\naa\n-b\nbb"
-a
aa
-b
bb
```

Je veux mettre sur une seule ligne les blocs séparés par le séparateur "-" 
 => soit les blocs : a\naa et b\nbb

Et à l'affichage on remplacera les \n du blocs par un autre caractère, 
 disons "|" :
 => soit les blocs : a|aa et b|bb

Schématiquement on a :
<debut><separateur_1><bloc_A><separateur_2><bloc_B><fin>

L'opération consiste à remplacer le séparateur d'enregistrement 
 RS (Record Separator) (par défaut "\n") par autre chose.

En réalité separateur_1 est "-" tout seul (car en début)
 mais separateur_2 est "\n-"

Il en résulte que soit on est au début ou soit commence par "\n" 
 et qu'il est suivi par "-" ou bien c'est la fin

On obtient :
```sh
user@host:~# echo -e "-a\naa\n-b\nbb" \
 | awk -v RS="(^|\n)(-|$)" '{ print ">" $0 "<" }'
><
>a
aa<
>b
bb<
```
La première ligne est vide, car nous avons défini ce qui sépare,
 mais au début on sépare avec du vide, la solution est donc de ne pas
 afficher le 1 enregistrement
 => NR (number of records processed) > 1
On obtient :
```sh
user@host:~# echo -e "-a\naa\n-b\nbb" \
 | awk -v RS="(^|\n)(-|$)" 'NR > 1 { print ">" $0 "<" }'
>a
aa<
>b
bb<
```

Il ne reste plus qu'à transformer les "\n" des blocs en "|"
La première ligne est vide, car nous avons défini ce qui sépare,
 mais au début on sépare avec du vide, la solution est donc de ne pas
 afficher le 1 enregistrement
 => NR (number of records processed) > 1
On obtient :
```sh
user@host:~# echo -e "-a\naa\n-b\nbb" \
 | awk -v RS="(^|\n)(-|$)" 'NR > 1 { gsub ( /\n/ , "|" ) ; print }'
a|aa
b|bb
```

Pour généraliser, on peut remplacer "-" par n'importe quel séparateur
 en début de ligne :
 ```sh
 user@host:~# awk -v RS="(^|\n)(SEPARATOR-|$)" \
  'NR > 1 { gsub ( /\n/ , "|" ) ; print }'
 ```
 
Exemple pratique, retourner les interfaces iproute2 :
 ```sh
ip ad \
| awk -v RS="(^|\n)([0-9]+: |$)" \
'NR > 1 { gsub ( /\n/ , "|" ) ; print }'
lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc ...
eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc ...
 ```
