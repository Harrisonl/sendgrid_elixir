defmodule SendGrid.Contacts.Recipients do
  @moduledoc """
  Module to interact with modifying contacts.

  See SendGrid's [Contact API Docs](https://sendgrid.com/docs/API_Reference/Web_API_v3/Marketing_Campaigns/contactdb.html)
  for more detail.
  """

  alias SendGrid.Contacts.Recipient

  @base_api_url "/v3/contactdb/recipients"

  @doc """
  Adds a contact to the contacts list available in Marketing Campaigns.

  When adding a contact, an email address must provided at a minimum. Custom
  fields that have already been created can added as well.

  ## Options

  * `:api_key` - API key to use with the request.

  ## Examples

      alias SendGrid.Contacts.Recipient

      {:ok, recipient_id} = add(Recipient.build("test@example.com", %{"name" => "John Doe"}))

      {:ok, recipient_id} = add(Recipient.build("test@example.com"))
  """
  @spec add(Recipient.t(), [SendGrid.api_key()]) ::
          {:ok, String.t()} | {:error, [String.t(), ...]}
  def add(%Recipient{} = recipient, opts \\ []) when is_list(opts) do
    with {:ok, response} <- SendGrid.post(@base_api_url, recipient, opts) do
      handle_recipient_result(response)
    end
  end

  # Handles the result when errors are present.
  defp handle_recipient_result(%{body: %{"error_count" => count} = body}) when count > 0 do
    errors = Enum.map(body["errors"], & &1["message"])

    {:error, errors}
  end

  # Handles the result when it's valid.
  defp handle_recipient_result(%{body: %{"persisted_recipients" => [recipient_id]}}) do
    {:ok, recipient_id}
  end

  defp handle_recipient_result(%{body: %{"persisted_recipients" => []}}) do
    {:ok, ["No changes applied for recipient"]}
  end

  # Below is Copied from https://github.com/alexgaribay/sendgrid_elixir/pull/36/files
  # Once that PR is Merged, please merge this one.
  @doc """
  Allows you to perform a search on all of your Marketing Campaigns recipients
  {:ok, recipients} = search(%{"first_name" => "test"})
  """
  @spec search(map) :: {:ok, list(map)} | {:error, list(String.t)}
  def search(opts) do
    query = URI.encode_query(opts)
    with {:ok, response} <- SendGrid.get("#{@base_api_url}/search?#{query}") do
      handle_search_result(response)
    end
  end

  defp handle_search_result(%{body: body = %{"error_count" => count }}) when count > 0 do
    errors = Enum.map(body["errors"], & &1["message"])

    {:error, errors}
  end

  # Handles the result when it's valid.
  defp handle_search_result(%{body: %{"recipients" => recipients}}) do
    {:ok, recipients}
  end

  defp handle_search_result(_) do
    {:error, ["Unexpected error"]}
  end
end
