#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

normalize_guess() {
  local guess=$1
  local digits

  if [[ $guess == -* ]]; then
    digits=${guess#-}
    printf '%s\n' "$((-10#$digits))"
  elif [[ $guess == +* ]]; then
    digits=${guess#+}
    printf '%s\n' "$((10#$digits))"
  else
    printf '%s\n' "$((10#$guess))"
  fi
}

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
GUESS_COUNT=0

echo "Enter your username:"
read USERNAME

# Keep usernames within the database limit while allowing normal shell input.
USER_RESULT=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_RESULT ]]; then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)" >/dev/null
else
  IFS='|' read GAMES_PLAYED BEST_GAME <<< "$USER_RESULT"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS

  if [[ ! $GUESS =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  GUESS=$(normalize_guess "$GUESS")
  (( GUESS_COUNT++ ))

  if (( GUESS == SECRET_NUMBER )); then
    break
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"

record_game() {
  $PSQL "UPDATE users
  SET games_played = games_played + 1,
      best_game = CASE
        WHEN best_game IS NULL OR $GUESS_COUNT < best_game THEN $GUESS_COUNT
        ELSE best_game
      END
  WHERE username='$USERNAME'" >/dev/null
}

record_game
