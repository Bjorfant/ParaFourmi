template Type randomchoice(vector<Type> v) {
	int random = rand() % v.size();
	return v[random];
}

//retourne vrai si la case d'indice "index" est sur le bord gauche de la matrice
int isOnLeftBorder(index) {
	return index%taille == 0;
}

//retourne vrai si la case d'indice "index" est sur le bord droit de la matrice 
int isOnRightBorder(index) {
	return index%taille == taille - 1;
}

//retourne vrai si la case d'indice "index" est sur le bord supérieur de la matrice
int isOnTopBorder(index) {
	return index%(taille**2) - taille < 0;
}

//retourne vrai si la case d'indice "index" est sur le bord inférieur de la matrice
int isOnBottomBorder(index) {
	return index%(taille**2) + taille >= taille**2;
}

//retourne vrai si la case d'indice "index" est sur le bord avant de la matrice 
int isOnFrontBorder(index) {
	return index + (taille**2) >= taille**3;
}

//retourne vrai si la case d'indice "index" est sur le bord arrière de la matrice
int isOnBackBorder(index) {
	return index < taille**2;
}

bool isAccessible(index) {
	# Calcul du nombre de voisins
	if (!isOnRightBorder(index)) {
		if (matfourmi[index+1] == State::GRAIN)
			return true;
	}
	if (!isOnLeftBorder(index)) {
		if (matfourmi[index-1] == State::GRAIN)
			return true;
	}
	if (!isOnTopBorder(index)) {
		if matfourmi[index-taille] == State::GRAIN)
			return true;
	}
	if (!isOnBottomBorder(index)) {
		if (matfourmi[index+taille] == State::GRAIN)
			return true;
	}
	if (!isOnFrontBorder(index)) {
		if (matfourmi[index+taille**2] == State::GRAIN)
			return true;
	}
	if (!isOnBackBorder(index)) {
		if (matfourmi[index-taille**2] == State::GRAIN)
			return true;
	}
	return false;
}

int deplacement_alea(voisins) {
	if voisins.size() >= 1
		return randomchoice(voisins);
	else:
		return -1;
}

//récupère les voisins d'une case de la matrice
//possibilité de filtrer les voisins par une liste d'état que l'on cherche 
//si la liste est vide on renvoit tous les voisins
vector <int> listeVoisins(int index, vector <int> filtre) {
	voisins=[]
	all = filtre == [] //verifie si il a une condition
	if (!isOnRightBorder(index))
		if (all || matfourmi[index+1] in filtre)
			voisins.push_back(index+1);
	if (!isOnLeftBorder(index))
		if (all || matfourmi[index-1] in filtre)
			voisins.push_back(index-1);
	if (!isOnTopBorder(index))
		if (all || matfourmi[index-taille] in filtre)
			voisins.push_back(index-taille);
	if (!isOnBottomBorder(index))
		if (all || matfourmi[index+taille] in filtre)
			voisins.push_back(index+taille);
	if (!isOnFrontBorder(index))
		if (all || matfourmi[index+taille**2] in filtre)
			voisins.push_back(index+taille**2);
	if (!isOnBackBorder(index))
		if (all || matfourmi[index-taille**2] in filtre)
			voisins.push_back(index-taille**2);
	return voisins;
}

vector <int> listeVoisinsAccessibles(int index) {
	vector <int> v;
	v.push_back(State::ACCESSIBLE);
	return listeVoisins(index, v);
}
	
vector <int> listeVoisinsActifs(int index) {
	vector <int> v;
	v.push_back(State::ACCESSIBLE);
	v.push_back(State::TRANSIT);
	return listeVoisins(index, v);
	
	
int indexFourmiVoisine(int index) {
	if (!isOnRightBorder(index))
		if (matTransitions[index+1] == index || matTransitions[index+1] == -1*index-2)
			return index+1;
	if (!isOnLeftBorder(index))
		if (matTransitions[index-1] == index || matTransitions[index-1] == -1*index-2)
			return index-1;
	if (!isOnTopBorder(index))
		if (matTransitions[index-taille] == index || matTransitions[index-taille] == -1*index-2)
			return index-taille;
	if (!isOnBottomBorder(index))
		if (matTransitions[index+taille] == index || matTransitions[index+taille] == -1*index-2)
			return index+taille;
	if (!isOnFrontBorder(index)) // A reformuler
		if (matTransitions[index+taille**2] == index || matTransitions[index+taille**2] == -1*index-2)
			return index+taille**2;
	if (!isOnBackBorder(index)) // A reformuler
		if (matTransitions[index-taille**2] == index || matTransitions[index-taille**2] == -1*index-2)
			return index-taille**2;
	return -1;
}
	
	
// index : position dans la matrice
// bloc ; état du bloc à la position "index"
int transition(int index, int bloc):
	int choix = rand() % 2;
	if (bloc==State::FOURMI || bloc==State::TRANSIT) {
		if (choix==0) { //Déplacement
			voisins = listeVoisinsAccessibles(index);
			return deplacement_alea(voisins);
		}
		else if (choix==1 && bloc == State::FOURMI) { //Ramassage
			vector <int> tmp;
			tmp.push_back(State::GRAIN);
			vector <int> voisins = listeVoisins(index, tmp);
			return deplacement_alea(voisins);
		}
		else if (choix==1 && bloc == State::TRANSIT { //Dépot
			vector <int> voisins = listeVoisinsAccessibles(index);
			if (deplacement_alea(voisins)==-1)
				return -1;
			else:
				return -1*deplacement_alea(voisins)-2;
		}
	}
	else
		return -1;
}

int transition2(int index) {
	int val = matTransitions[index];
	bool isDeparture = val != -1;
	int indexFourmi = indexFourmiVoisine(index);
	bool isArrival = indexFourmi != -1;
	
	if (isDeparture) {
		if (val > -1) //cas déplacement
			return State::ACCESSIBLE;
		else	//cas dépot
			return State::GRAIN;
	}
	else if (isArrival) {
		if (matTransitions[indexFourmi] > -1) { //cas déplacement
			if (matfourmi[index] == State::ACCESSIBLE) //cas déplacement simple
				return matfourmi[indexFourmi]; 
			else if (matfourmi[index] == State::GRAIN) //cas ramassage
				return State::TRANSIT;
		}
		else if (matTransitions[indexFourmi] < -1) {	//cas dépot
			return State::FOURMI;
		else
			cout << "ERREUR DE MERDE" << endl;
	}
	else
		return matfourmi[index];
}

vector <int> updateStates(int index, int bloc) {
	int nbVoisinsActifs = listeVoisinsActifs(index).size();
	if (bloc == State::VIDE || bloc == State::ACCESSIBLE) {
		if (isAccessible(index) && nbVoisinsActifs<=1)
			return State::ACCESSIBLE;
		else
			return State::VIDE;
	}
	else if (bloc == State::GRAIN && nbVoisinsActifs>1)
		return State::GRAIN_CONFLIT;
	else if (bloc == State::GRAIN_CONFLIT && nbVoisinsActifs<=1)
		return State::GRAIN;
	else:	
		return bloc;
}

int main() {

	int tailleMatrice = 3;
	int nbEtapes = 0;
	
	// A reprendre du fichier de tests
	
	cout << "Matrice initiale" << endl << matfourmi << endl;
	cout << "Combien d'etapes voulez vous realiser ?" << endl;
	cin >> nbEtapes;
	
	for (int i=0 ; i<nbEtapes ; i++) {
		cout << "Etape " << i << endl;
	}

}