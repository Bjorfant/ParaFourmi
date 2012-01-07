#include <thrust/for_each.h>
#include <thrust/device_vector.h>
#include <thrust/iterator/zip_iterator.h>
#include <iostream>
#include <vector>
#include <cstdlib>

using namespace std;

int taille = 3;


 typedef enum {
	VIDE=0,
	ACCESSIBLE=1,
	ACCESSIBLE_CONFLIT=2,
	GRAIN_CONFLIT=3,
	GRAIN=4,
	FOURMI=5,
	TRANSIT=6
} State;


//retourne vrai si la case d'indice "index" est sur le bord gauche de la matrice

int isOnLeftBorder(int index) {
	return index%taille == 0;
}

//retourne vrai si la case d'indice "index" est sur le bord droit de la matrice 

int isOnRightBorder(int index) {
	return index%taille == taille - 1;
}

//retourne vrai si la case d'indice "index" est sur le bord supérieur de la matrice

int isOnTopBorder(int index) {
	return index%(taille*taille) - taille < 0;
}

//retourne vrai si la case d'indice "index" est sur le bord inférieur de la matrice

int isOnBottomBorder(int index) {
	return index%(taille*taille) + taille >= taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord avant de la matrice 

int isOnFrontBorder(int index) {
	return index + (taille*taille) >= taille*taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord arrière de la matrice

int isOnBackBorder(int index) {
	return index < taille*taille;
}


/*
bool isAccessible(int index, thrust::device_vector<int> matfourmi) {
	// Calcul du nombre de voisins
	if (!isOnRightBorder(index)) {
		if (matfourmi[index+1] == GRAIN)
			return true;
	}
	if (!isOnLeftBorder(index)) {
		if (matfourmi[index-1] == GRAIN)
			return true;
	}
	if (!isOnTopBorder(index)) {
		if (matfourmi[index-taille] == GRAIN)
			return true;
	}
	if (!isOnBottomBorder(index)) {
		if (matfourmi[index+taille] == GRAIN)
			return true;
	}
	if (!isOnFrontBorder(index)) {
		if (matfourmi[index+taille*taille] == GRAIN)
			return true;
	}
	if (!isOnBackBorder(index)) {
		if (matfourmi[index-taille*taille] == GRAIN)
			return true;
	}
	return false;
}*/

struct moveIndex {

	const int delta, maxIndex;

	moveIndex(int _delta, int _maxIndex) : delta(_delta), maxIndex(_maxIndex) {}

	__host__ __device__
	int operator()(int index){
		return (index + delta)%maxIndex;
	}
};

struct isAccessible {

	template <typename Tuple>
	__host__ __device__
	void operator() (Tuple t) {
	
		int index = thrust::get<0>(t);
		int blocAtLeft = thrust::get<1>(t);
		int blocAtRight = thrust::get<2>(t);
		int blocAtTop = thrust::get<3>(t);
		int blocAtBottom = thrust::get<4>(t);
		int blocAtFront = thrust::get<5>(t);
		int blocAtBack = thrust::get<6>(t);
		
		// Calcul du nombre de voisins
		if (!isOnLeftBorder(index)) {
			if (blocAtLeft == GRAIN)
				thrust::get<7>(t) = true;
		}
		if (!isOnRightBorder(index)) {
			if (blocAtRight == GRAIN)
				thrust::get<7>(t) = true;
		}
		if (!isOnTopBorder(index)) {
			if (blocAtTop == GRAIN)
				thrust::get<7>(t) = true;
		}
		if (!isOnBottomBorder(index)) {
			if (blocAtBottom == GRAIN)
				thrust::get<7>(t) = true;
		}
		if (!isOnFrontBorder(index)) {
			if (blocAtFront == GRAIN)
				thrust::get<7>(t) = true;
		}
		if (!isOnBackBorder(index)) {
			if (blocAtBack] == GRAIN)
				thrust::get<7>(t) = true;
		}
		thrust::get<7>(t) = false;
	}
};


int deplacement_alea(vector <int> voisins) {
	if (voisins.size() >= 1)
		return voisins[0];
	else
		return -1;
}

//récupère les voisins d'une case de la matrice
//possibilité de filtrer les voisins par une liste d'état que l'on cherche 
//si la liste est vide on renvoit tous les voisins

vector <int> listeVoisins(int index, thrust::device_vector <int> filtre, thrust::host_vector<int> &matfourmi) {
	vector <int> voisins;
	bool all = filtre.empty(); //verifie s'il y a une condition
	if (!isOnRightBorder(index))
		if (all || thrust::find(filtre.begin(), filtre.end(), matfourmi[index+1]) != filtre.end())
			voisins.push_back(index+1);
	if (!isOnLeftBorder(index))
		if (all || thrust::find(filtre.begin(), filtre.end(), matfourmi[index-1]) != filtre.end())
			voisins.push_back(index-1);
	if (!isOnTopBorder(index))
		if (all || thrust::find(filtre.begin(), filtre.end(), matfourmi[index-taille]) != filtre.end())
			voisins.push_back(index-taille);
	if (!isOnBottomBorder(index))
		if (all || thrust::find(filtre.begin(), filtre.end(), matfourmi[index+taille]) != filtre.end())
			voisins.push_back(index+taille);
	if (!isOnFrontBorder(index))
		if (all || thrust::find(filtre.begin(), filtre.end(), matfourmi[index+taille*taille]) != filtre.end())
			voisins.push_back(index+taille*taille);
	if (!isOnBackBorder(index))
		if (all || thrust::find(filtre.begin(), filtre.end(), matfourmi[index-taille*taille]) != filtre.end())
			voisins.push_back(index-taille*taille);
	return voisins;
}


vector <int> listeVoisinsAccessibles(int index, thrust::host_vector<int> &matfourmi) {
	vector <int> v;
	v.push_back(ACCESSIBLE);
	return listeVoisins(index, v, matfourmi);
}


vector <int> listeVoisinsActifs(int index, thrust::host_vector<int> &matfourmi) {
	vector <int> v;
	v.push_back(ACCESSIBLE);
	v.push_back(TRANSIT);
	return listeVoisins(index, v, matfourmi);
}

/*
int indexFourmiVoisine(int index, , vector<int> &matTransitions) {
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
}*/


struct genereMatrix {
	__host__ __device__
	int operator()(int bloc) {
		
		int states[] = {ACCESSIBLE, GRAIN};
		
		int x = bloc %2;
		return states[x];
	}
};

struct placeAnt {
	const int a;

	placeAnt(int _a) : a(_a) {}
	
	__host__ __device__
	int operator()(int bloc) {
		if (bloc == ACCESSIBLE)
			
			//if (a%6 < 2 && getNbFourmi() < 1) {
				//nbFourmi += 1;
				return FOURMI;
			//}
		return bloc;
	}
};



struct updateStates2 {
	
	template <typename Tuple>
	__host__ __device__
	void operator()(Tuple t) {
		/*t(0) = matfourmi
		t(1) = voisins actifs
		t(2) = isaccessible
		t(3) = matfourmi
		*/
		int bloc = thrust::get<0>(t);
		int nbVoisinsActifs = thrust::get<1>(t);
		bool isAccessible = thrust::get<2>(t);
		
		if (bloc == VIDE || bloc == ACCESSIBLE) {
			if (isAccessible && nbVoisinsActifs<=1)
				thrust::get<3>(t) = ACCESSIBLE;
			else
				thrust::get<3>(t) = VIDE;
		}
		else if (bloc == GRAIN && nbVoisinsActifs>1)
			thrust::get<3>(t) = GRAIN_CONFLIT;
		else if (bloc == GRAIN_CONFLIT && nbVoisinsActifs<=1)
			thrust::get<3>(t) = GRAIN;
		else
			thrust::get<3>(t) = bloc;
		thrust::get<3>(t) = -1;
	}
	
};

thrust::host_vector<int> updateStates (thrust::host_vector<int> &matFourmi) {
	
	// Création des matrices décalées
	moveIndex mv_right = moveIndex(1 ,tailleTotale);
	moveIndex mv_left = moveIndex(-1 ,tailleTotale);
	moveIndex mv_top = moveIndex(-taille ,tailleTotale);
	moveIndex mv_bottom = moveIndex(taille ,tailleTotale);
	moveIndex mv_front = moveIndex(taille*taille ,tailleTotale);
	moveIndex mv_back = moveIndex(-taille*taille ,tailleTotale);
	
	counting_iterator<int> begin(0);
	counting_iterator<int> end(tailleTotale);

	vector <int> rightIndexes(tailleTotale);
	vector <int> leftIndexes(tailleTotale);
	vector <int> topIndexes(tailleTotale);
	vector <int> bottomIndexes(tailleTotale);
	vector <int> frontIndexes(tailleTotale);
	vector <int> backIndexes(tailleTotale);
	 
	thrust::transform(begin, end, rightIndexes.begin(), mv_right());
	thrust::transform(begin, end, leftIndexes.begin(), mv_left());
	thrust::transform(begin, end, topIndexes.begin(), mv_top());
	thrust::transform(begin, end, bottomIndexes.begin(), mv_bottom());
	thrust::transform(begin, end, frontIndexes.begin(), mv_front());
	thrust::transform(begin, end, backIndexes.begin(), mv_back());

	
	// Initialisation de la matrice des voisins actifs ---------- SEQUENTIEL : Modifier la fonction listeVoisinsActifs
	thrust::host_vector<int> matNbVoisinsActifs;
	for(int i=0 ; i<matFourmi.size() ; i++)
		matNbVoisinsActifs.push_back(listeVoisinsActifs(i,matFourmi).size());
	
	
	// Initialisation de la matrice des booléens accessibles
	thrust::host_vector<int> matIsAccessible;
	thrust::for_each(
		thrust::make_zip_iterator(
			thrust::make_tuple(begin, leftIndexes.begin(), rightIndexes.begin(), topIndexes.begin(), bottomIndexes.begin(), frontIndexes.begin(), backIndexes.begin(), matIsAccessible.begin())
		),
		thrust::make_zip_iterator(
			thrust::make_tuple(end, leftIndexes.end(), rightIndexes.end(), topIndexes.end(), bottomIndexes.end(), frontIndexes.end(), backIndexes.end(), matIsAccessible.end())
		),
		isAccessible()
	);
		
		
	// Application des conditions d'updateStates2 sur les 3 matrices transformées en tuple (la fonction transform ne prend que 2 elements max)
	thrust::for_each(
		thrust::make_zip_iterator(
			thrust::make_tuple(matFourmi.begin(), matNbVoisinsActifs.begin(), matIsAccessible.begin(), matFourmi.begin())
		),
		thrust::make_zip_iterator(
			thrust::make_tuple(matFourmi.end(), matNbVoisinsActifs.end(), matIsAccessible.end(), matFourmi.end())
		),
		updateStates2()
	);
	
	return matFourmi;
}

/*
// index : position dans la matrice
// bloc ; état du bloc à la position "index"
int transition(int index, int bloc) {
	int choix = rand() % 2;
	if (bloc==FOURMI || bloc==TRANSIT) {
		if (choix==0) { //Déplacement
			voisins = listeVoisinsAccessibles(index);
			return deplacement_alea(voisins);
		}
		else if (choix==1 && bloc == FOURMI) { //Ramassage
			vector <int> tmp;
			tmp.push_back(GRAIN);
			vector <int> voisins = listeVoisins(index, tmp);
			return deplacement_alea(voisins);
		}
		else if (choix==1 && bloc == TRANSIT) { //Dépot
			vector <int> voisins = listeVoisinsAccessibles(index);
			if (deplacement_alea(voisins)==-1)
				return -1;
			else:
				return -1*deplacement_alea(voisins)-2;
		}
	}
	else
		return -1;
}*/
/*
int transition2(int index) {
	int val = matTransitions[index];
	bool isDeparture = val != -1;
	int indexFourmi = indexFourmiVoisine(index);
	bool isArrival = indexFourmi != -1;

	if (isDeparture) {
		if (val > -1) //cas déplacement
			return ACCESSIBLE;
		else	//cas dépot
			return GRAIN;
	}
	else if (isArrival) {
		if (matTransitions[indexFourmi] > -1) { //cas déplacement
			if (matfourmi[index] == ACCESSIBLE) //cas déplacement simple
				return matfourmi[indexFourmi]; 
			else if (matfourmi[index] == GRAIN) //cas ramassage
				return TRANSIT;
		}
		else if (matTransitions[indexFourmi] < -1) {	//cas dépot
			return FOURMI;
		else
			cout << "ERREUR DE MERDE" << endl;
	}
	else
		return matfourmi[index];
}
*/

int main() {
	
	int taille = 3;
	
	srand ( time(NULL) );
	
	thrust::host_vector<int> matFourmi(taille*taille*taille);

	clock_t t1;
	clock_t t2;
	t1 = clock();

	t2=clock()-t1;
	t1 = clock();
	
	// Génération de la matrice
	thrust::generate(matFourmi.begin(), matFourmi.end(), rand);
	thrust::transform(matFourmi.begin(), matFourmi.end(), matFourmi.begin(), genereMatrix());
	
	// Placement d'une fourmi -------- A modifier : faire une boucle pour plusieurs fourmis
	int randvalue = rand() % taille*taille*taille;
	matFourmi[randvalue] = FOURMI;
	
	// Mise à jour de la matrice
	matFourmi = updateStates(matFourmi);
	
	t2 = clock() - t1;

	for(int i = 0; i < taille*taille*taille; i++) {
		std::cout<< matFourmi[i] << std::endl;
	}
	return 0;
}

/*
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

}*/

/*
nvcc  --machine 32 -ccbin "C:\Program Files\Microsoft Visual Studio 10.0\VC\bin"  -I "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.0\include" test.cu -o test
*/