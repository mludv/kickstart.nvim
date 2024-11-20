import os
import argparse
import json

import httpx
from anthropic import AnthropicBedrock

AWS_ACCESS_KEY_ID = os.getenv("BEDROCK_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY= os.getenv("BEDROCK_SECRET_ACCESS_KEY")

if not AWS_ACCESS_KEY_ID or not AWS_SECRET_ACCESS_KEY:
    raise RuntimeError("Provide env variables BEDROCK_ACCESS_KEY_ID and BEDROCK_SECRET_ACCESS_KEY")


def main(args):

    # http://54.150.176.53:809
    bedrock_proxy = os.getenv('BEDROCK_PROXY', None)

    # Create httpx client with proxy
    http_client = httpx.Client(proxy=bedrock_proxy)

    client = AnthropicBedrock(
        # Authenticate by either providing the keys below or use the default AWS credential providers, such as
        # using ~/.aws/credentials or the "AWS_SECRET_ACCESS_KEY" and "AWS_ACCESS_KEY_ID" environment variables.
        aws_access_key=AWS_ACCESS_KEY_ID,
        aws_secret_key=AWS_SECRET_ACCESS_KEY,
        # Temporary credentials can be used with aws_session_token.
        # Read more at https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp.html.
        # and if that's not present, we default to us-east-1. Note that we do not read ~/.aws/config for the region.
        aws_region="us-west-2",
        http_client=http_client,
    )

    messages = json.loads(args.data)

    with client.messages.stream(
        max_tokens=2048,
        model="anthropic.claude-3-5-sonnet-20241022-v2:0",
        system=args.system_prompt or 'You are a helpful assistant',
        messages=messages,
    ) as stream:
        for text in stream.text_stream:
            print(text, end="", flush=True)
        print()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", help='The JSON encoded messages to send to anthropic.', required=True)
    parser.add_argument("--system-prompt", help='A system prompt to add to the request.')

    args = parser.parse_args()

    main(args)
