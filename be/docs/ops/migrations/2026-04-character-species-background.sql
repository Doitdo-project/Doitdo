CREATE TABLE character_species_backgrounds (
  species VARCHAR(20) NOT NULL,
  birth_background TEXT NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  PRIMARY KEY (species)
);
