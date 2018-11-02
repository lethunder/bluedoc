module DocsHelper
  def doc_title_tag(doc)
    return "" if doc.blank?
    return "" if doc.repository.blank?
    return "" if doc.repository.user.blank?

    link_to doc.title, doc.to_path, class: "doc-link"
  end
end
