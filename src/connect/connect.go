package connect

import (
	"io"
	"net/http"

	"github.com/rs/zerolog/log"
)

func Connect(apiUrl string) []byte {
	// Connect to the site
	res, err := http.Get(apiUrl)
	if err != nil {
		log.Error().Err(err).Msg("Could not connect to site")
	}
	defer res.Body.Close()
	// Read the body
	body, err := io.ReadAll(res.Body)
	if err != nil {
		log.Error().Err(err).Msg("Could not read body")
	}
	return body
}
