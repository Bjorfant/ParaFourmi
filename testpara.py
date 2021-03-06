#-*- coding:UTF-8 -*-

from datapara import *
import random
import os
import logging

#constante determinant l'état de chaque bloc
class State:
	VIDE=0
	ACCESSIBLE=1
	ACCESSIBLE_CONFLIT=2
	GRAIN_CONFLIT=3
	GRAIN=4 # Finalement utile
	FOURMI=5
	TRANSIT=6

nbFourmi = 0

#affichage de la matrice
def printMatrix(mat):
	buf = ""
	for i in range(0, len(mat)):
		if i%taille == 0:
			buf += "\n"
		if i%(taille**2) == 0:
			buf += "\n"
		if mat[i] == State.FOURMI:
			if os.name != 'nt':
				buf += "\033[22;31m"+str(mat[i]) + " \033[m"
			else:
				buf += str(mat[i]) + " "
		elif mat[i] == State.TRANSIT:
			if os.name != 'nt':
				buf += "\033[01;37m"+str(mat[i]) + " \033[m"
			else:
				buf += str(mat[i]) + " "
		else:
			buf += str(mat[i]) + " "
	print(buf)
	
def genereMatrix(elem):
	return random.choice([State.ACCESSIBLE,State.ACCESSIBLE,State.ACCESSIBLE,State.GRAIN,State.GRAIN,State.GRAIN])

def placeAnt(bloc):
	global nbFourmi
	if bloc == State.ACCESSIBLE:
		if random.choice([0, 1, 2, 3, 4, 5]) < 2 and nbFourmi < 1:
			nbFourmi += 1
			return State.FOURMI
	return bloc


#retourne vrai si la case d'indice "index" est sur le bord gauche de la matrice
def isOnLeftBorder(index):
	return index%taille == 0

#retourne vrai si la case d'indice "index" est sur le bord droit de la matrice 
def isOnRightBorder(index):
	return index%taille == taille - 1

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
	if not isOnRightBorder(case):
		if matfourmi[case+1] == State.GRAIN:
			return True
	if not isOnLeftBorder(case):
		if matfourmi[case-1] == State.GRAIN:
			return True
	if not isOnTopBorder(case):
		if matfourmi[case-taille] == State.GRAIN:
			return True
	if not isOnBottomBorder(case):
		if matfourmi[case+taille] == State.GRAIN:
			return True
	if not isOnFrontBorder(case):
		if matfourmi[case+taille**2] == State.GRAIN:
			return True
	if not isOnBackBorder(case):
		if matfourmi[case-taille**2] == State.GRAIN:
			return True
	return False

	'''
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
	return False'''

def deplacement_alea(voisins):
	logging.debug("Destinations potentielles :")
	logging.debug(voisins)
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
	return listeVoisins(case, [State.FOURMI, State.TRANSIT])
	
def indexFourmiVoisine(case):
	if not isOnRightBorder(case):
		if matTransitions[case+1] == case or matTransitions[case+1] == -1*case-2:
			return case+1
	if not isOnLeftBorder(case):
		if matTransitions[case-1] == case or matTransitions[case-1] == -1*case-2:
			return case-1
	if not isOnTopBorder(case):
		if matTransitions[case-taille] == case or matTransitions[case-taille] == -1*case-2:
			return case-taille
	if not isOnBottomBorder(case):
		if matTransitions[case+taille] == case or matTransitions[case+taille] == -1*case-2:
			return case+taille
	if not isOnFrontBorder(case): # A reformuler
		if matTransitions[case+taille**2] == case or matTransitions[case+taille**2] == -1*case-2:
			return case+taille**2
	if not isOnBackBorder(case): # A reformuler
		if matTransitions[case-taille**2] == case or matTransitions[case-taille**2] == -1*case-2:
			return case-taille**2
	return -1

# index : position dans la matrice
# bloc ; état du bloc à la position "index"
def transition(index, bloc):
	choix = random.choice([0,1])
	if bloc==State.FOURMI or bloc==State.TRANSIT:
		logging.debug("La fourmi a l'index "+str(index)+" a choisi")
		if choix==0: #Déplacement
			logging.debug("Le déplacement")
			voisins = listeVoisinsAccessibles(index)
			return deplacement_alea(voisins)
		elif choix==1 and bloc == State.FOURMI: #Ramassage
			logging.debug("Le ramassage")
			voisins = listeVoisins(index, [State.GRAIN])
			return deplacement_alea(voisins)
		elif choix==1 and bloc == State.TRANSIT: #Dépot
			logging.debug("Le dépot")
			voisins = listeVoisins(index, [State.ACCESSIBLE])
			if deplacement_alea(voisins)==-1:
				return -1
			else:
				return -1*deplacement_alea(voisins)-2
	else:
		return -1
	
def transition2(index):
	val = matTransitions[index]
	isDeparture = val != -1
	indexFourmi = indexFourmiVoisine(index)
	isArrival = indexFourmi != -1
	logging.debug("La case "+str(index)+" "+str(isDeparture)+" "+str(isArrival)+" "+str(indexFourmi))
	if isDeparture:
		if val > -1: #cas déplacement
			return State.ACCESSIBLE
		else:	#cas dépot
			return State.GRAIN
	elif isArrival:
		if matTransitions[indexFourmi] > -1:#cas déplacement
			if matfourmi[index] == State.ACCESSIBLE: #cas déplacement simple
				return matfourmi[indexFourmi] 
			elif matfourmi[index] == State.GRAIN: #cas ramassage
				return State.TRANSIT
		elif matTransitions[indexFourmi] < -1:	#cas dépot
			return State.FOURMI
		else:
			logging.debug("ERREUR DE MERDE")
	else:
		return matfourmi[index]

	'''if matTransitions[index] < -1:
		return 1
	elif indexFourmiVoisine(index) != -1:
		if index < -1:
			if matfourmi[-1*index+2] == State.ACCESSIBLE:
				return State.FOURMI
			else:
				return indexFourmiVoisine(-1*index+2)
		else:
			if matfourmi[index] == State.GRAIN:
				return State.TRANSIT
			else:
				return indexFourmiVoisine(index)
	else:
		return matfourmi[index]'''

def updateStates(index, bloc):
	nbVoisinsActifs = len(listeVoisinsActifs(index))
	if bloc == State.VIDE or bloc == State.ACCESSIBLE:
		if isAccessible(index) and nbVoisinsActifs<=1:
			return State.ACCESSIBLE
		else:
			return State.VIDE
	elif bloc == State.GRAIN and nbVoisinsActifs>1:
		return State.GRAIN_CONFLIT
	elif bloc == State.GRAIN_CONFLIT and nbVoisinsActifs<=1:
		return State.GRAIN
	else:	
		return bloc


##########################################
################ MAIN ####################
##########################################
logging.basicConfig(level=logging.DEBUG)
if os.name == 'nt':
	clear = lambda: os.system('cls')
else:
	clear = lambda: os.system('clear')


taille = 3

#generation de la matrice (sans les fourmis pour ne pas avoir de fourmis volantes
matfourmi = map1 (genereMatrix, range(taille**3))[0]
#mise à jour des états pour les blocs vides et accessibles 
matfourmi = map2 (updateStates, range(taille**3), matfourmi)[0]
#placement des fourmis aléatoirement sur les blocs accessibles
matfourmi = map1 (placeAnt, matfourmi)[0]
matfourmi = map2 (updateStates, range(taille**3), matfourmi)[0]
matTransitions = [0]*(taille**3)

print("Matrice initiale")
printMatrix(matfourmi)
nbEtapes = input("Combien d'étapes voulez vous réaliser ? \n")
nbEtapes = int(nbEtapes)

for i in range(0, nbEtapes):
	clear()
	print("\nMatrice temps", str(i))
	matTransitions = map2 (transition, range(taille**3), matfourmi)[0]
	print("\nMatrice temporaire")
	printMatrix(matTransitions)
	
	matfourmi = map1(transition2, range(taille**3))[0]
	#print("\nMatrice T+1")
	
	matfourmi = map2(updateStates, range(taille**3), matfourmi)[0]
	printMatrix(matfourmi)
	input("Appuyez sur une touche pour continuer...")
	
