package verbose.logging

import org.openapitools.client.apis.DefaultApi

fun main() {
  val api = DefaultApi()
  val post = api.getPost(id = 1)
  println("Fetched post: $post")
}