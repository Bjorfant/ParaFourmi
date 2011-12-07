#-*- coding:latin1 -*-

from datapara import *
import random

'''
0 : vide
1 : accessible
2 : plein
3 : grain
4 : fourmi
5 : fourmi-grain
'''

def printMatrix(mat):
    buf = ""
    for i in range(0, len(mat)):
   	 if i%taille == 0:
   		 buf += "\n"
   	 if i%(taille**2) == 0:
   		 buf += "\n"
   	 buf += str(mat[i])
    print(buf)

taille = 3
matfourmi = [0,0,0,1,1,1,3,3,3,0,4,0,1,1,1,3,3,3,0,0,0,1,1,1,3,3,3]
matfourmi2 = [0]*(taille**3)
matfourmi3 = [0]*(taille**3)
print("Matrice initiale")
printMatrix(matfourmi)


	
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

def deplacement_alea(voisins):
	if len(voisins) >= 1:
		return random.choice(voisins)
	else:
		return -1
		
def listevoisinsaccessibles(case):
	# Calcul du nombre de voisins
	voisins=[]
	if not isOnRightBorder(case):
		if matfourmi[case+1] == 1:
			voisins.append(case+1)
	if not isOnLeftBorder(case):
		if matfourmi[case-1] == 1:
			voisins.append(case-1)
	if not isOnTopBorder(case):
		if matfourmi[case-taille] == 1:
			voisins.append(case-taille)
	if not isOnBottomBorder(case):
		if matfourmi[case+taille] == 1:
			voisins.append(case+taille)
	if not isOnFrontBorder(case): # A reformuler
		if matfourmi[case+taille**2] == 1:
			voisins.append(case+taille**2)
	if not isOnBackBorder(case): # A reformuler
		if matfourmi[case-taille**2] == 1:
			voisins.append(case-taille**2)
	return voisins

def listefourmisvoisines(case):
	# Calcul du nombre de voisins
	voisins=[]
	if not isOnRightBorder(case):
		if matfourmi[case+1] == 4:
			voisins.append(case+1)
	if not isOnLeftBorder(case):
		if matfourmi[case-1] == 4:
			voisins.append(case-1)
	if not isOnTopBorder(case):
		if matfourmi[case-taille] == 4:
			voisins.append(case-taille)
	if not isOnBottomBorder(case):
		if matfourmi[case+taille] == 4:
			voisins.append(case+taille)
	if not isOnFrontBorder(case): # A reformuler
		if matfourmi[case+taille**2] == 4:
			voisins.append(case+taille**2)
	if not isOnBackBorder(case): # A reformuler
		if matfourmi[case-taille**2] == 4:
			voisins.append(case-taille**2)
	return voisins
	
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
	
	voisins = listevoisinsaccessibles(case)
	nbvoisins = len(voisins)
	if etat==4 or etat==5:
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

matfourmi2 = map1 ( transition, range(taille**3) )[0]
print("\nMatrice temporaire")
printMatrix(matfourmi2)

matfourmi3 = map1(transition2, range(taille**3))[0]
print("\nMatrice T+1")
printMatrix(matfourmi3)