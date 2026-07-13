package ua.kbase.kbase.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "seq_users_gen")
    @SequenceGenerator(name = "seq_users_gen", sequenceName = "seq_users", allocationSize = 1)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String username;

    @Column(nullable = false, length = 100)
    private String password;

    @Column(length = 100)
    private String email;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "role_id")
    private Role role;

    @Column(nullable = false)
    @Builder.Default
    private boolean active = true;

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
