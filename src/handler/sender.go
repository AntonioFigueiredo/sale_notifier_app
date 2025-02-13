package handler

import (
	"net/smtp"
	"os"

	"github.com/rs/zerolog/log"
)

func SendMail() {
	sender := os.Getenv("EMAIL")
	password := os.Getenv("PASSWORD")
	recipient := os.Getenv("RECIPIENT")
	smtpServer := os.Getenv("SMTP_SERVER")
	smtpPort := os.Getenv("SMTP_PORT")
	smtpServerPort := smtpServer + ":" + smtpPort
	if err := smtp.SendMail(smtpServerPort, smtp.PlainAuth("", sender, password, smtpServer), sender, []string{recipient}, []byte("Subject: Test Email\n\nThis is a test email")); err != nil {
		log.Error().Err(err).Msg("Could not send email")
	}
}
