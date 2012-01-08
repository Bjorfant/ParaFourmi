#include <thrust/for_each.h>
#include <thrust/device_vector.h>
#include <thrust/iterator/counting_iterator.h>
#include <thrust/iterator/permutation_iterator.h>
#include <thrust/iterator/zip_iterator.h>
#include <iostream>
#include <vector>
#include <cstdlib>

#define taille 3

using namespace std;


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

//retourne vrai si la case d'indice "index" est sur le bord sup�rieur de la matrice

int isOnTopBorder(int index) {
	return index%(taille*taille) - taille < 0;
}

//retourne vrai si la case d'indice "index" est sur le bord inf�rieur de la matrice

int isOnBottomBorder(int index) {
	return index%(taille*taille) + taille >= taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord avant de la matrice 

int isOnFrontBorder(int index) {
	return index + (taille*taille) >= taille*taille*taille;
}

//retourne vrai si la case d'indice "index" est sur le bord arri�re de la matrice

int isOnBackBorder(int index) {
	return index < taille*taille;
}


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
			if (blocAtBack == GRAIN)
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

//r�cup�re les voisins d'une case de la matrice
//possibilit� de filtrer les voisins par une liste d'�tat que l'on cherche 
//si la liste est vide on renvoit tous les voisins
/*
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
}*/


struct listeNbVoisinsActifs {

	template <typename Tuple>
	__host__ __device__
	void operator()(Tuple t){

		int filtre = FOURMI;
		
		int index = thrust::get<0>(t);
		int blocAtLeft = thrust::get<1>(t);
		int blocAtRight = thrust::get<2>(t);
		int blocAtTop = thrust::get<3>(t);
		int blocAtBottom = thrust::get<4>(t);
		int blocAtFront = thrust::get<5>(t);
		int blocAtBack = thrust::get<6>(t);
		int voisins = 0;
		
		bool all = true; //verifie s'il y a une condition
		if (!isOnLeftBorder(index))
			if (all || blocAtLeft == filtre)
				voisins++;
		if (!isOnRightBorder(index))
			if (all || blocAtRight == filtre)
				voisins++;
		if (!isOnTopBorder(index))
			if (all || blocAtTop == filtre)
				voisins++;
		if (!isOnBottomBorder(index))
			if (all || blocAtBottom == filtre)
				voisins++;
		if (!isOnFrontBorder(index))
			if (all || blocAtFront == filtre)
				voisins++;
		if (!isOnBackBorder(index))
			if (all || blocAtBack == filtre)
				voisins++;
		thrust::get<7>(t) = voisins;
	}
};



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
	
	int tailleTotale = matFourmi.size();
	
	// Cr�ation des matrices d�cal�es
	thrust::counting_iterator<int> begin(0);
	thrust::counting_iterator<int> end(tailleTotale);

	thrust::host_vector <int> rightIndexes(tailleTotale);
	thrust::host_vector <int> leftIndexes(tailleTotale);
	thrust::host_vector <int> topIndexes(tailleTotale);
	thrust::host_vector <int> bottomIndexes(tailleTotale);
	thrust::host_vector <int> frontIndexes(tailleTotale);
	thrust::host_vector <int> backIndexes(tailleTotale);
	 
	thrust::transform(begin, end, leftIndexes.begin(), moveIndex(-1 ,tailleTotale));
	thrust::transform(begin, end, rightIndexes.begin(), moveIndex(1 ,tailleTotale));
	thrust::transform(begin, end, topIndexes.begin(), moveIndex(-taille ,tailleTotale));
	thrust::transform(begin, end, bottomIndexes.begin(), moveIndex(taille ,tailleTotale));
	thrust::transform(begin, end, frontIndexes.begin(), moveIndex(taille*taille ,tailleTotale));
	thrust::transform(begin, end, backIndexes.begin(), moveIndex(-taille*taille ,tailleTotale));

	
	// Initialisation de la matrice des bool�ens accessibles
	thrust::host_vector<int> matIsAccessible;
	thrust::for_each(
		thrust::make_zip_iterator(
			thrust::make_tuple(
				begin, 
				thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.begin()), 
				matIsAccessible.begin()
			)
		),
		thrust::make_zip_iterator(
			thrust::make_tuple(
				end, 
				thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.end()), 
				matIsAccessible.end()
			)
		),
		isAccessible()
	);
	
	
	// Initialisation de la matrice des voisins actifs
	thrust::host_vector<thrust::host_vector<int>> matVoisinsActifs;
	thrust::host_vector<int> matNbVoisinsActifs;
	
	thrust::for_each(
		thrust::make_zip_iterator(
			thrust::make_tuple(
				begin, 
				thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.begin()), 
				thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.begin()), 
				matNbVoisinsActifs.begin()
			)
		),
		thrust::make_zip_iterator(
			thrust::make_tuple(
				end, 
				thrust::make_permutation_iterator(matFourmi.begin(), leftIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), rightIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), topIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), bottomIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), frontIndexes.end()), 
				thrust::make_permutation_iterator(matFourmi.begin(), backIndexes.end()), 
				matNbVoisinsActifs.end()
			)
		),
		listeNbVoisinsActifs()
	);
	
		
		
	// Application des conditions d'updateStates2 sur les 3 matrices transform�es en tuple (la fonction transform ne prend que 2 elements max)
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
// bloc ; �tat du bloc � la position "index"
int transition(int index, int bloc) {
	int choix = rand() % 2;
	if (bloc==FOURMI || bloc==TRANSIT) {
		if (choix==0) { //D�placement
			voisins = listeVoisinsAccessibles(index);
			return deplacement_alea(voisins);
		}
		else if (choix==1 && bloc == FOURMI) { //Ramassage
			vector <int> tmp;
			tmp.push_back(GRAIN);
			vector <int> voisins = listeVoisins(index, tmp);
			return deplacement_alea(voisins);
		}
		else if (choix==1 && bloc == TRANSIT) { //D�pot
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
		if (val > -1) //cas d�placement
			return ACCESSIBLE;
		else	//cas d�pot
			return GRAIN;
	}
	else if (isArrival) {
		if (matTransitions[indexFourmi] > -1) { //cas d�placement
			if (matfourmi[index] == ACCESSIBLE) //cas d�placement simple
				return matfourmi[indexFourmi]; 
			else if (matfourmi[index] == GRAIN) //cas ramassage
				return TRANSIT;
		}
		else if (matTransitions[indexFourmi] < -1) {	//cas d�pot
			return FOURMI;
		else
			cout << "ERREUR DE MERDE" << endl;
	}
	else
		return matfourmi[index];
}*/


int main() {
	
	srand ( time(NULL) );
	
	thrust::host_vector<int> matFourmi(taille*taille*taille);

	clock_t t1;
	clock_t t2;
	t1 = clock();

	t2=clock()-t1;
	t1 = clock();
	
	// G�n�ration de la matrice
	thrust::generate(matFourmi.begin(), matFourmi.end(), rand);
	thrust::transform(matFourmi.begin(), matFourmi.end(), matFourmi.begin(), genereMatrix());
	
	// Placement d'une fourmi -------- A modifier : faire une boucle pour plusieurs fourmis
	int randvalue = rand() % taille*taille*taille;
	matFourmi[randvalue] = FOURMI;
	
	// Mise � jour de la matrice
	matFourmi = updateStates(matFourmi);
	
	t2 = clock() - t1;
	
	cout << "Temps �coul� : " << t2 << endl;

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
nvcc --machine 32 -ccbin "C:\Program Files\Microsoft Visual Studio 10.0\VC\bin"  -I "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v4.0\include" testpara.cu -o testpara
*/