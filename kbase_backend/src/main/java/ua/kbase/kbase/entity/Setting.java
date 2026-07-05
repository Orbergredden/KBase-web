package ua.kbase.kbase.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "settings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Setting {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "seq_settings_gen")
    @SequenceGenerator(name = "seq_settings_gen", sequenceName = "seq_settings", allocationSize = 1)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String alias;

    @Column(length = 50)
    private String section;

    @Column(length = 50)
    private String subject;

    @Column(length = 50)
    private String name;

    @Column(length = 50)
    private String value;

    @Column(length = 200)
    private String descr;

    @Column(name = "date_created")
    private LocalDateTime dateCreated;

    @Column(name = "date_modified")
    private LocalDateTime dateModified;

    @Column(name = "user_created", length = 30)
    private String userCreated;

    @Column(name = "user_modified", length = 30)
    private String userModified;

    @PrePersist
    protected void onCreate() {
        if (dateCreated == null) {
            dateCreated = LocalDateTime.now();
        }
        if (dateModified == null) {
            dateModified = LocalDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        dateModified = LocalDateTime.now();
    }
}
