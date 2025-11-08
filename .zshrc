# ZSH configuration per questo progetto

# Carica la configurazione globale di zsh
if [ -f ~/.zshrc ]; then
    source ~/.zshrc
fi

# Sovrascrivi HISTFILE per usare la cronologia locale del progetto
export HISTFILE="${PWD}/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

# Assicurati che la cronologia venga salvata immediatamente
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY