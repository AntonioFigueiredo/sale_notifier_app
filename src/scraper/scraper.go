package scraper

import (
	"io"
	"net/http"
	"regexp"

	"github.com/rs/zerolog/log"
)

func GetInfo(info string, url string) string {
	if url == "" {
		log.Fatal().Msg("No URL found in wishlist.txt")
	}

	response, err := http.Get(url)
	if err != nil {
		log.Fatal().Err(err).Msg("Error fetching the webpage")
	}
	defer response.Body.Close()

	body, err := io.ReadAll(response.Body)
	if err != nil {
		log.Fatal().Err(err).Msg("Error reading response body")
	}

	titleRegex := regexp.MustCompile(`"` + info + `"\s*:\s*"([^"]+)"`)
	matches := titleRegex.FindStringSubmatch(string(body))

	if len(matches) > 1 {
		return matches[1]
	}

	log.Info().Msgf("%s not found.", info)
	return ""
}

func GetNSUID(url string) string {
	return GetInfo("offdeviceNsuID", url)
}

func GetGameTitle(url string) string {
	return GetInfo("gameTitle", url)
}

func GetPrice(url string) string {
	return GetInfo("offdeviceProductPrice", url)
}
