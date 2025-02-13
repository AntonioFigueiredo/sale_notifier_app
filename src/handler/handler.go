package handler

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/rs/zerolog/log"
)

type Message struct {
	Personalized bool   `json:"personalized"`
	Country      string `json:"country"`
	Prices       []struct {
		TitleID      int64  `json:"title_id"`
		SalesStatus  string `json:"sales_status"`
		RegularPrice struct {
			Amount   string `json:"amount"`
			Currency string `json:"currency"`
			RawValue string `json:"raw_value"`
		} `json:"regular_price"`
		DiscountPrice struct {
			Amount        string    `json:"amount"`
			Currency      string    `json:"currency"`
			RawValue      string    `json:"raw_value"`
			StartDatetime time.Time `json:"start_datetime"`
			EndDatetime   time.Time `json:"end_datetime"`
		} `json:"discount_price"`
		GoldPoint struct {
			BasicGiftGp     string `json:"basic_gift_gp"`
			BasicGiftRate   string `json:"basic_gift_rate"`
			ConsumeGp       string `json:"consume_gp"`
			ExtraGoldPoints []any  `json:"extra_gold_points"`
			GiftGp          string `json:"gift_gp"`
			GiftRate        string `json:"gift_rate"`
		} `json:"gold_point"`
	} `json:"prices"`
}

func unmarshal(body []byte) (Message, bool) {
	var data Message
	if err := json.Unmarshal(body, &data); err != nil {
		log.Error().Err(err).Msg("Could not unmarshal json bytestream")
		return Message{}, false
	}
	log.Debug().Msgf("Title ID: %s", data.Prices[0].DiscountPrice.Amount)
	return data, data.Prices[0].DiscountPrice.Amount != ""
}

func GetPrice(body []byte) string {
	data, hasDiscount := unmarshal(body)
	if hasDiscount {
		fmt.Printf("Title has a discount: %s\n", data.Prices[0].DiscountPrice.RawValue)
		return data.Prices[0].DiscountPrice.RawValue
	}
	fmt.Printf("Returning regular price: %s\n", data.Prices[0].RegularPrice.RawValue)
	return data.Prices[0].RegularPrice.RawValue
}

func GetFormPrice(body []byte) string {
	data, hasDiscount := unmarshal(body)

	if hasDiscount {
		return data.Prices[0].DiscountPrice.Amount
	}
	return data.Prices[0].RegularPrice.Amount
}
