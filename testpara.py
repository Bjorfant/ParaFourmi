#-*- coding:UTF-8 -*-

from datapara import *
import random
import os

#constante determinant l'état de chaque bloc
class State:
	VIDE=0
	ACCESSIBLE=1
	PLEIN=2
	GRAIN=3
	FOURMI=4
	TRANSIT=5

#affichage de la matrice
def printMatrix(mat):
    buf = ""
    for i in range(0, len(mat)):
   	 if i%taille == 0:
   		 buf += "\n"
   	 if i%(taille**2) == 0:
   		 buf += "\n"
   	 buf += str(mat[i])
    print(buf)
	
def genereMatrix(taille):
	return random.choice([1,1,1,3,3,3,4])


#retourne vrai si la case d'indice "index" est sur le bord gauche de la matrice
def isOnLeftBorder(index):
	return index%taille == 0

#retourne vrai si la case d'indice "index" est sur le bord droit de la matrice 
def isOnRightBorder(index):
	return index%(taille - 1) == 0

#retourne vrai si la case d'indice "index" est sur le bord supérieur de la matrice
def isOnTopBorder(index):
	return index%(taille**2) - taille < 0

#retourne vrai si la case d'indice "index" est sur le bord inférieur de la matrice
def isOnBottomBorder(index):
	return index%(taille**2) + taille >= taille**2

#retourne vrai si la case d'indice "index" est sur le bord avant de la matrice 
def isOnFrontBorder(index):
	return index + (taille**2) >= taille**3

#retourne vrai si la case d'indice "index" est sur le bord arrière de la matrice
def isOnBackBorder(index):
	return index < taille**2


def isAccessible(case):
	# Calcul du nombre de voisins
	voisins=[]
	if not isOnRightBorder(case):
		if matfourmi[case+1] == State.PLEIN or matfourmi[case+1] == State.GRAIN:
			return True
	if not isOnLeftBorder(case):
		if matfourmi[case-1] == State.PLEIN or matfourmi[case-1] == State.GRAIN:
			return True
	if not isOnTopBorder(case):
		if matfourmi[case-taille] == State.PLEIN or matfourmi[case-taille] == State.GRAIN:
			return True
	if not isOnBottomBorder(case):
		if matfourmi[case+taille] == State.PLEIN or matfourmi[case+taille] == State.GRAIN:
			return True
	if not isOnFrontBorder(case):
		if matfourmi[case+taille**2] == State.PLEIN or matfourmi[case+taille**2] == State.GRAIN:
			return True
	if not isOnBackBorder(case):
		if matfourmi[case-taille**2] == State.PLEIN or matfourmi[case-taille**2] == State.GRAIN:
			return True
	return False

def isGrain(case):
	# Calcul du nombre de voisins
	voisins=[]
	if not isOnRightBorder(case):
		if matfourmi[case+1] == State.VIDE or matfourmi[case+1] == State.ACCESSIBLE:
			return True
	if not isOnLeftBorder(case):
		if matfourmi[case-1] == State.VIDE or matfourmi[case-1] == State.ACCESSIBLE:
			return True
	if not isOnTopBorder(case):
		if matfourmi[case-taille] == State.VIDE or matfourmi[case-taille] == State.ACCESSIBLE:
			return True
	if not isOnBottomBorder(case):
		if matfourmi[case+taille] == State.VIDE or matfourmi[case+taille] == State.ACCESSIBLE:
			return True
	if not isOnFrontBorder(case):
		if matfourmi[case+taille**2] == State.VIDE or matfourmi[case+taille**2] == State.ACCESSIBLE:
			return True
	if not isOnBackBorder(case):
		if matfourmi[case-taille**2] == State.VIDE or matfourmi[case-taille**2] == State.ACCESSIBLE:
			return True
	return False

def deplacement_alea(voisins):
	if len(voisins) >= 1:
		return random.choice(voisins)
	else:
		return -1

#récupère les voisins d'une case de la matrice
#possibilité de filtrer les voisins par une liste d'état que l'on cherche 
#si la liste est vide on renvoit tous les voisins
def listeVoisins(index, filtre):
	voisins=[]
	all = filtre == [] #verifie si il a une condition
	if not isOnRightBorder(index):
		if all or matfourmi[index+1] in filtre:
			voisins.append(index+1)
	if not isOnLeftBorder(index):
		if all or matfourmi[index-1] in filtre:
			voisins.append(index-1)
	if not isOnTopBorder(index):
		if all or matfourmi[index-taille] in filtre:
			voisins.append(index-taille)
	if not isOnBottomBorder(index):
		if all or matfourmi[index+taille] in filtre:
			voisins.append(index+taille)
	if not isOnFrontBorder(index):
		if all or matfourmi[index+taille**2] in filtre:
			voisins.append(index+taille**2)
	if not isOnBackBorder(index):
		if all or matfourmi[index-taille**2] in filtre:
			voisins.append(index-taille**2)
	return voisins

def listeVoisinsAccessibles(index):
	return listeVoisins(index, [State.ACCESSIBLE])

def listeVoisinsActifs(case):
	return listeVoisins(index, [State.FOURMI, State.TRANSIT])
	
def etatfourmivoisine(case):
	# Calcul du nombre de voisins
	if not isOnRightBorder(case):
		if matfourmi2[case+1] == case:
			return matfourmi[case+1]
	if not isOnLeftBorder(case):
		if matfourmi2[case-1] == case:
			return matfourmi[case-1]
	if not isOnTopBorder(case):
		if matfourmi2[case-taille] == case:
			return matfourmi[case-taille]
	if not isOnBottomBorder(case):
		if matfourmi2[case+taille] == case:
			return matfourmi[case+taille]
	if not isOnFrontBorder(case): # A reformuler
		if matfourmi2[case+taille**2] == case:
			return matfourmi[case+taille**2]
	if not isOnBackBorder(case): # A reformuler
		if matfourmi2[case-taille**2] == case:
			return matfourmi[case-taille**2]
	return -1

def transition(case):
	etat=matfourmi[case]
	if etat==4 or etat==5:
		voisins = listeVoisinsAccessibles(case)
		print("Liste des voisins accessibles :",voisins)
		return deplacement_alea(voisins)
	else:
		return -1
	
def transition2(case):
	if matfourmi2[case] != -1:
		return 1
	elif etatfourmivoisine(case) != -1:
		return etatfourmivoisine(case)
	else:
		return matfourmi[case]

def updateStates(case):
	state = matfourmi[case]
	if state == State.VIDE or state == State.ACCESSIBLE:
		if isAccessible(case):
			return State.ACCESSIBLE
		else:
			return State.VIDE
	if state == State.PLEIN or state == State.GRAIN:
		if isGrain(case):
			return State.GRAIN
		else:
			return State.PLEIN
	else:	
		return state


##########################################
################ MAIN ####################
##########################################
clear = lambda: os.system('clear')

taille = 5
'''
matfourmi =[0,0,0,
1,1,1,
3,3,3,
0,0,0,
1,4,1,
3,3,3,
0,0,0,
1,1,1,
3,3,3]'''
matfourmi = map1 (genereMatrix, range(taille**3) )[0]
matfourmi = map1 (updateStates, range(taille**3))[0]
matfourmi2 = [0]*(taille**3)
matfourmi3 = [0]*(taille**3)

nbEtapes = input("Combien d'étapes voulez vous réaliser ? \n")
nbEtapes = int(nbEtapes)
print("Matrice initiale")
printMatrix(matfourmi)

for i in range(0, nbEtapes):
	clear()
	print("\nMatrice temps", str(i))
	matfourmi2 = map1 (transition, range(taille**3) )[0]
	print("\nMatrice temporaire")
	printMatrix(matfourmi2)
	
	matfourmi = map1(transition2, range(taille**3))[0]
	#print("\nMatrice T+1")
	#printMatrix(matfourmi3)
	
	#matfourmi = map1(updateStates, range(taille**3))[0]
	printMatrix(matfourmi)
	input("press your penis to continue")
	
	
	
	
''' FAILS

Après updateStats :

213
311
243

413
331
243 <-- le 2 est fail

331
113
331
'''