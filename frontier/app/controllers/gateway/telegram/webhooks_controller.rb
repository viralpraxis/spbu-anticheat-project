# frozen_string_literal: true

class Gateway::Telegram::WebhooksController < ApplicationController
  rescue_from StandardError do |exception|
    Rails.logger.error(exception)

    raise exception unless Rails.env.production?

    head :ok
  end

  before_action do
    next if input.chat_object.present?

    head :unprocessable_entity
  end

  def notify
    dispatch_command

    head :ok
  end

  private

    def dispatch_command
      service_result = TelegramForm::ProcessRequestService.call(
        telegram_form, input:
      )

      if service_result.success?
        reply_with(event_response(service_result.event, service_result.context))
      else
        reply_with(event_response(service_result.reason, {}))
      end
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def event_response(event, context)
      # NOTE: dirty!
      return context.fetch(:preview) if event == :succeeded_preview

      i18n_key = event.dup

      Rails.logger.info(event)
      Rails.logger.info(context)

      context = if event == :created_upload
        { filename: context.fetch(:upload).filename }
      elsif event == :updated_to_course_provided_stage
        assignments = telegram_form.course.assignments.pluck(:title).join("\n")
        last_telegram_form = telegram_form.telegram_chat.telegram_forms.completed.order(updated_at: :desc).take
        i18n_key = if last_telegram_form
          "#{event}.with_existing_submission"
        else
          "#{event}.default"
        end
        { assignments: }
      elsif event == :telegram_chat_group_provided
        courses = Course.active.where(group: telegram_chat.group).pluck(:title).join("\n")
        i18n_key = :courses_not_found if courses.blank?

        { courses: Course.active.where(group: telegram_chat.group).pluck(:title).join("\n") }
      elsif event == :updated_to_uploads_provided_stage
        assignments = context.fetch(:assignments).pluck(:title).map.with_index(1) { |val, index| "#{index}. #{val}" }.join("\n")
        { assignments: }
      else
        {}
      end

      I18n.with_locale(:ru) { t i18n_key, context }
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def t(key, context = {})
      I18n.t(key, **context, scope: "controllers.gateway.telegram.webhooks.messages")
    end

    def telegram_form
      return @telegram_form if defined?(@telegram_form)

      @telegram_form = telegram_chat.telegram_forms.incompleted.take
    end

    # rubocop:disable MultilineMethodCallIndentation
    def telegram_chat
      @telegram_chat ||= TelegramChat
        .create_with(username: input.username)
        .find_or_create_by!(external_identifier: input.chat_id)
    end
    # rubocop:enable MultilineMethodCallIndentation

    def reply_with(message) = api_client.send_message(chat_id: input.chat_id, text: message)

    def input = @input ||= TelegramForm::ParseInputService.call(params).input

    def api_client
      @api_client ||= Telegram::Bot::Client.new(Rails.application.credentials.services.telegram_bot)
    end
end
